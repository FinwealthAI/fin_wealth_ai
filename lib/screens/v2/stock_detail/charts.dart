part of '../stock_detail_screen_v2.dart';

/// Biểu đồ dùng trong các tab: giá, định giá (PE/PB), tăng trưởng.
extension on _StockDetailScreenV2State {
  // ---------- Charts ----------
  Widget _buildPriceChart() {
    if (_loadingRatio) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errRatio != null && _ratio == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadRatio,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }
    final priceHistory = _ratio?['price_history'] as Map<String, dynamic>?;
    final closeRaw = (priceHistory?['close'] as List<dynamic>?) ?? const [];
    final priceLabels = (priceHistory?['labels'] as List<dynamic>?) ?? const [];
    final price = closeRaw
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
    if (price.isEmpty) {
      return const Center(
          child: Text('Chưa có dữ liệu giá',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final yMin = price.reduce((a, b) => a < b ? a : b);
    final yMax = price.reduce((a, b) => a > b ? a : b);

    double? norm(double? v) {
      if (v == null) return null;
      if (v > yMax * 5 && v >= 1000) return v / 1000.0;
      return v;
    }

    final avgTarget = norm(_toD(_overview?['avg_target_price']));
    Map? techLevels;
    if (!_loadingTechnical && _technical != null) {
      techLevels = ((_technical!['data'] as Map?)?['levels']) as Map?;
    }
    final support = norm(_toD(techLevels?['nearest_support']));
    final resistance = norm(_toD(techLevels?['nearest_resistance']));

    final valSpots = <FlSpot>[];
    if (!_loadingValuationHistory && _valuationHistory != null) {
      final histList = _valuationHistory!['history'] as List<dynamic>? ?? [];
      if (histList.isNotEmpty) {
        // Sort valuation entries by date ascending (DateTime-aware) so we can
        // forward-fill across non-trading dates with a two-pointer walk.
        final entries = <MapEntry<DateTime, double>>[];
        for (final h in histList) {
          final map = h as Map<String, dynamic>;
          final dateStr = map['date'] as String?;
          final val = _toD(map['avg_target_price']);
          if (dateStr == null || val == null) continue;
          final dt = DateTime.tryParse(dateStr);
          if (dt == null) continue;
          entries.add(MapEntry(dt, val));
        }
        entries.sort((a, b) => a.key.compareTo(b.key));

        if (entries.isNotEmpty) {
          final sampleRaw = entries.first.value;
          final lastPrice = price.isNotEmpty ? price.last : 0.0;
          final scale = (sampleRaw > 0 && lastPrice > 0 && sampleRaw < lastPrice / 100) ? 1000.0 : 1.0;
          int ptr = 0;
          double? lastVal;
          for (int i = 0; i < priceLabels.length; i++) {
            final lbl = priceLabels[i].toString();
            final lblDt = DateTime.tryParse(lbl);
            if (lblDt != null) {
              while (ptr < entries.length &&
                  !entries[ptr].key.isAfter(lblDt)) {
                lastVal = norm(entries[ptr].value * scale);
                ptr++;
              }
            }
            if (lastVal != null) {
              valSpots.add(FlSpot(i.toDouble(), lastVal));
            }
          }
        }
      }
    }

    double cMin = yMin;
    double cMax = yMax;
    for (final y in [avgTarget, support, resistance]) {
      if (y != null) {
        if (y < cMin) cMin = y;
        if (y > cMax) cMax = y;
      }
    }
    for (final spot in valSpots) {
      if (spot.y < cMin) cMin = spot.y;
      if (spot.y > cMax) cMax = spot.y;
    }

    final span = (cMax - cMin).abs();
    final pad = span < 0.1 ? 1.0 : span * 0.05;
    final yLo = cMin - pad;
    final yHi = cMax + pad * 4; // extra headroom for labels

    final hLines = <HorizontalLine>[];
    void addHLine(double? y, Color c, String lbl) {
      if (y == null || y <= yLo || y >= yHi) return;
      hLines.add(HorizontalLine(
        y: y,
        color: c,
        strokeWidth: 1.0,
        dashArray: const [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700),
          labelResolver: (_) => lbl,
        ),
      ));
    }

    if (valSpots.isEmpty) {
      addHLine(avgTarget, Colors.orangeAccent, 'ĐG TB');
    }
    addHLine(support, AppColors.successDark, 'HT');
    addHLine(resistance, Colors.redAccent, 'KC');

    // Signal markers placed slightly below the price (web parity: prices[idx]*0.95)
    final labelIndex = <String, int>{};
    for (int i = 0; i < priceLabels.length; i++) {
      labelIndex[priceLabels[i].toString()] = i;
    }
    final signalSpots = <FlSpot>[];
    final signalStrategyMap = <int, List<String>>{};
    final seenIdx = <int>{};
    if (!_loadingSignals) {
      for (final s in _signals) {
        if (s is! Map) continue;
        var date = s['date'] as String?;
        if (date == null) continue;
        date = date.split('T').first;
        var idx = labelIndex[date];
        if (idx == null) {
          final parts = date.split('-');
          if (parts.length == 3) {
            final dmy = '${parts[2]}/${parts[1]}/${parts[0]}';
            idx = labelIndex[dmy];
          }
        }
        if (idx == null || idx >= price.length) continue;
        final strat =
            (s['strategy_name'] ?? s['strategy'] ?? 'Mua').toString();
        signalStrategyMap.putIfAbsent(idx, () => []).add(strat);
        if (!seenIdx.contains(idx)) {
          seenIdx.add(idx);
          signalSpots.add(FlSpot(idx.toDouble(), price[idx] * 0.95));
        }
      }
      signalSpots.sort((a, b) => a.x.compareTo(b.x));
    }

    // Track barIndex → series kind for tooltip rendering
    const priceBarIdx = 0;
    final valBarIdx = valSpots.isNotEmpty ? 1 : -1;
    final signalBarIdx = signalSpots.isNotEmpty
        ? (valSpots.isNotEmpty ? 2 : 1)
        : -1;

    return LineChart(
      LineChartData(
        minY: yLo,
        maxY: yHi,
        extraLinesData: hLines.isEmpty
            ? null
            : ExtraLinesData(horizontalLines: hLines),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.darkBorder.withValues(alpha: 0.4),
            strokeWidth: 0.5,
            dashArray: const [3, 3],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.darkSurface.withValues(alpha: 0.95),
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            getTooltipItems: (spots) {
              String? dateText;
              if (spots.isNotEmpty) {
                final i = spots.first.x.toInt();
                if (i >= 0 && i < priceLabels.length) {
                  final raw = priceLabels[i].toString();
                  final dt = DateTime.tryParse(raw);
                  dateText = dt != null
                      ? DateFormat('dd/MM/yyyy').format(dt)
                      : raw;
                }
              }
              bool headerEmitted = false;
              return spots.map((s) {
                LineTooltipItem build(
                    String label, Color color, String value) {
                  final children = <TextSpan>[
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '  $value',
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ];
                  if (!headerEmitted && dateText != null) {
                    headerEmitted = true;
                    return LineTooltipItem(
                      '$dateText\n',
                      const TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      children: children,
                    );
                  }
                  return LineTooltipItem(
                    '',
                    const TextStyle(fontSize: 11),
                    children: children,
                  );
                }

                if (s.barIndex == priceBarIdx) {
                  return build('Giá', AppColors.brandPrimaryDark,
                      s.y.toStringAsFixed(2));
                }
                if (s.barIndex == valBarIdx) {
                  return build('ĐG TB', Colors.orangeAccent,
                      s.y.toStringAsFixed(2));
                }
                if (s.barIndex == signalBarIdx) {
                  final names = signalStrategyMap[s.x.toInt()] ?? const [];
                  final txt = names.isEmpty ? 'Mua' : names.join(', ');
                  return build('Theo dõi', AppColors.successDark, txt);
                }
                return null;
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < price.length; i++)
                FlSpot(i.toDouble(), price[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.18,
            color: AppColors.brandPrimaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimaryDark.withValues(alpha: 0.35),
                  AppColors.brandPrimaryDark.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (valSpots.isNotEmpty)
            LineChartBarData(
              spots: valSpots,
              isCurved: false,
              color: Colors.orangeAccent,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),
          if (signalSpots.isNotEmpty)
            LineChartBarData(
              spots: signalSpots,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) =>
                    const _TriangleDotPainter(color: AppColors.successDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValuationChart() {
    if (_loadingRatio) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final r = _ratio;
    if (r == null) {
      return const Center(
          child: Text('Chưa có dữ liệu',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final isPE = _valuationKind == 'PE';
    final raw = (isPE ? r['pe_data'] : r['pb_data']) as List<dynamic>?;
    final ys = (raw ?? const [])
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
    if (ys.isEmpty) {
      return const Center(
          child: Text('Không có dữ liệu định giá',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final color = isPE
        ? AppColors.brandPrimaryDark
        : AppColors.brandSecondaryDark;
    final yMin = ys.reduce((a, b) => a < b ? a : b);
    final yMax = ys.reduce((a, b) => a > b ? a : b);
    final avg = (isPE ? r['avg_pe_1y'] : r['avg_pb_1y']) as num?;
    
    double chartMin = yMin;
    double chartMax = yMax;
    if (avg != null) {
      if (avg < chartMin) chartMin = avg.toDouble();
      if (avg > chartMax) chartMax = avg.toDouble();
    }
    final span = (chartMax - chartMin).abs();
    final pad = span < 0.05 ? 0.5 : span * 0.05;

    return LineChart(
      LineChartData(
        minY: chartMin - pad,
        maxY: chartMax + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.darkBorder.withValues(alpha: 0.4),
            strokeWidth: 0.5,
            dashArray: const [3, 3],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.darkSurface.withValues(alpha: 0.95),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (spots) {
              return spots.map((s) {
                if (s.barIndex == 1) {
                  return LineTooltipItem(
                    'Trung bình: ${s.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return LineTooltipItem(
                  '${isPE ? 'P/E' : 'P/B'}: ${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < ys.length; i++)
                FlSpot(i.toDouble(), ys[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (avg != null)
            LineChartBarData(
              spots: [
                FlSpot(0, avg.toDouble()),
                FlSpot((ys.length - 1).toDouble(), avg.toDouble()),
              ],
              isCurved: false,
              color: Colors.redAccent,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    if (_loadingGrowth) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_errGrowth != null && _growth == null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: TextButton.icon(
            onPressed: _loadGrowth,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }
    final g = _growth;
    if (g == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Chưa có dữ liệu',
            style: TextStyle(color: AppColors.darkTextMuted))),
      );
    }

    List<String> labels = ((g['labels'] as List?) ?? []).map((e) => e?.toString() ?? '').toList();
    List<double> revenue = ((g['abs_revenue'] as List?) ?? [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble()).toList();
    List<double> profit = ((g['abs_profit'] as List?) ?? [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble()).toList();
    List<double?> revGrowth = ((g['revenue_growth'] as List?) ?? [])
        .map((e) => e == null ? null : (e as num).toDouble()).toList();
    List<double?> profGrowth = ((g['profit_growth'] as List?) ?? [])
        .map((e) => e == null ? null : (e as num).toDouble()).toList();

    if (_growthPeriod == 'year') {
      final currentYear = DateTime.now().year;
      final validIdx = <int>[];
      for (int i = 0; i < labels.length; i++) {
        final lbl = labels[i];
        final dt = DateTime.tryParse(lbl);
        if (dt != null && dt.year >= currentYear) {
          continue;
        }
        validIdx.add(i);
      }
      labels = validIdx.map((i) => labels[i]).toList();
      revenue = validIdx.map((i) => i < revenue.length ? revenue[i] : 0.0).toList();
      profit = validIdx.map((i) => i < profit.length ? profit[i] : 0.0).toList();
      revGrowth = validIdx.map((i) => i < revGrowth.length ? revGrowth[i] : null).toList();
      profGrowth = validIdx.map((i) => i < profGrowth.length ? profGrowth[i] : null).toList();
    }

    if (revenue.isEmpty && profit.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Không có số liệu tăng trưởng',
            style: TextStyle(color: AppColors.darkTextMuted))),
      );
    }

    final n = [revenue.length, profit.length, labels.length]
        .reduce((a, b) => a > b ? a : b);

    String shortLabel(String iso) {
      if (iso.length < 7) return iso;
      final p = iso.split('-');
      if (p.length < 2) return iso;
      final y = p[0].substring(2);
      final m = int.tryParse(p[1]) ?? 0;
      if (_growthPeriod == 'year') return '20$y';
      return 'Q${(m / 3).ceil()}/$y';
    }

    // Shared layout constants — must match exactly between bar and line charts
    // so the plot areas overlap correctly in the Stack.
    const double leftReserved  = 38; // trục trái: giá trị tuyệt đối
    const double rightReserved = 42; // trục phải: % tăng trưởng
    const double bottomReserved = 22;
    const double barW = 6.0;

    // ── Growth % range ────────────────────────────────────────────────────
    final allGrowth = [...revGrowth, ...profGrowth].whereType<double>().toList();
    final gMin = allGrowth.isEmpty ? -50.0
        : (allGrowth.reduce((a, b) => a < b ? a : b) - 15).clamp(-300.0, -10.0);
    final gMax = allGrowth.isEmpty ? 100.0
        : (allGrowth.reduce((a, b) => a > b ? a : b) + 15).clamp(10.0, 400.0);

    FlSpot? toSpot(int i, List<double?> list) {
      if (i >= list.length || list[i] == null) return null;
      return FlSpot(i.toDouble(), list[i]!);
    }
    final revSpots  = [for (int i = 0; i < n; i++) toSpot(i, revGrowth)].whereType<FlSpot>().toList();
    final profSpots = [for (int i = 0; i < n; i++) toSpot(i, profGrowth)].whereType<FlSpot>().toList();
    final hasGrowth = revSpots.isNotEmpty || profSpots.isNotEmpty;

    // ── Bar chart ─────────────────────────────────────────────────────────
    final barData = BarChartData(
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.darkBorder, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: leftReserved,
            getTitlesWidget: (v, meta) {
              if (v == meta.max || v == meta.min) return const SizedBox.shrink();
              final s = v.abs() >= 1000
                  ? '${(v / 1000).toStringAsFixed(0)}k'
                  : v.toStringAsFixed(0);
              return Text(s,
                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9));
            },
          ),
        ),
        // Ẩn right axis — nhường cho LineChart overlay
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: rightReserved),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReserved,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(shortLabel(labels[i]),
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9)),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (int i = 0; i < n; i++)
          BarChartGroupData(x: i, barsSpace: 2, barRods: [
            BarChartRodData(
              toY: i < revenue.length ? revenue[i] : 0,
              width: barW,
              color: AppColors.brandSecondaryDark,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: i < profit.length ? profit[i] : 0,
              width: barW,
              color: AppColors.successDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ]),
      ],
    );

    // ── Line chart overlay ────────────────────────────────────────────────
    final lineData = hasGrowth
        ? LineChartData(
            // minX/maxX căn với spaceAround của bar chart
            minX: -0.5,
            maxX: n - 0.5,
            minY: gMin,
            maxY: gMax,
            clipData: const FlClipData.all(),
            backgroundColor: Colors.transparent,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: v.round() == 0 ? Colors.white30 : Colors.transparent,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              // Ẩn left — nhường cho BarChart
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false, reservedSize: leftReserved),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: rightReserved,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.max || v == meta.min) return const SizedBox.shrink();
                    return Text('${v.toInt()}%',
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 9));
                  },
                ),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false, reservedSize: bottomReserved),
              ),
            ),
            lineBarsData: [
              if (revSpots.isNotEmpty)
                LineChartBarData(
                  spots: revSpots,
                  isCurved: true,
                  color: AppColors.brandSecondaryDark,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AppColors.brandSecondaryDark, strokeWidth: 0),
                  ),
                  dashArray: [4, 3],
                ),
              if (profSpots.isNotEmpty)
                LineChartBarData(
                  spots: profSpots,
                  isCurved: true,
                  color: AppColors.successDark,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AppColors.successDark, strokeWidth: 0),
                  ),
                  dashArray: [4, 3],
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.darkSurface,
                getTooltipItems: (spots) => spots.map((s) {
                  final sign = s.y >= 0 ? '+' : '';
                  return LineTooltipItem(
                    '$sign${s.y.toStringAsFixed(1)}%',
                    TextStyle(color: s.bar.color, fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
          )
        : null;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          BarChart(barData),
          if (lineData != null) LineChart(lineData),
        ],
      ),
    );
  }
}
