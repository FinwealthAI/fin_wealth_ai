part of '../stock_detail_screen_v2.dart';

/// Tab 3: Chuỗi giá trị — nhóm chỉ số kinh tế liên quan + biểu đồ.
extension on _StockDetailScreenV2State {
  // ---------- Tab 3: Chuỗi giá trị ----------
  Widget _buildValueChain() {
    if (_loadingChain) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errChain != null && _chain == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadChain,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }

    final text = Theme.of(context).textTheme;
    final found = _chain?['found'] == true;
    final charts = (_chain?['charts'] as List?) ?? [];
    final groups = (_chain?['groups'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadChain,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Charts section ─────────────────────────────────────────────
          if (charts.isNotEmpty) ...[
            FwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bar_chart_rounded,
                        size: 16, color: AppColors.brandPrimaryDark),
                    const SizedBox(width: 6),
                    Text('Biểu đồ & Dữ liệu liên quan',
                        style: text.titleMedium),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  // Horizontal chart selector
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: charts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final ch = charts[i] as Map;
                        final active = i == _selectedChartIdx;
                        final corr = ch['correlation'] as String? ?? 'none';
                        return GestureDetector(
                          onTap: () => _rebuild(() => _selectedChartIdx = i),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 130),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.brandPrimaryDark
                                      .withValues(alpha: 0.15)
                                  : AppColors.darkSurface,
                              border: Border.all(
                                color: active
                                    ? AppColors.brandPrimaryDark
                                    : AppColors.darkBorder,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (corr != 'none') ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: corr == 'positive'
                                          ? AppColors.successDark
                                          : AppColors.dangerDark,
                                    ),
                                  ),
                                ],
                                Flexible(
                                  child: Text(
                                    ch['title'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? AppColors.brandPrimaryDark
                                          : AppColors.darkTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Time period filter
                  Row(
                    children: [
                      for (final (label, days) in [
                        ('6T', 180),
                        ('1N', 365),
                        ('3N', 1095),
                        ('Tất cả', -1),
                      ])
                        _ChartPeriodBtn(
                          label: label,
                          active: _chartPeriodDays == days,
                          onTap: () =>
                              _rebuild(() => _chartPeriodDays = days),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Chart
                  _buildEcoChart(charts[_selectedChartIdx] as Map),
                  // Breadcrumb + latest date
                  const SizedBox(height: 6),
                  _buildChartMeta(charts[_selectedChartIdx] as Map),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Value chain groups ─────────────────────────────────────────
          if (found && groups.isNotEmpty)
            FwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.account_tree_outlined,
                        size: 16, color: AppColors.brandPrimaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chuỗi giá trị: ${widget.ticker}',
                        style: text.titleMedium,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  // Timeline with vertical connector
                  Stack(
                    children: [
                      // Vertical line
                      Positioned(
                        left: 19,
                        top: 24,
                        bottom: 24,
                        child: Container(
                          width: 1,
                          color: AppColors.darkBorder,
                        ),
                      ),
                      Column(
                        children: [
                          for (int i = 0; i < groups.length; i++) ...[
                            _buildVcGroup(groups[i] as Map, i),
                            if (i < groups.length - 1)
                              const SizedBox(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (!found)
            FwCard(
              child: Column(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 36, color: AppColors.darkTextMuted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Chưa có sơ đồ chuỗi giá trị cho ${widget.ticker}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.darkTextMuted, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const List<_VcStyle> _vcStyles = [
    _VcStyle(
      iconData: Icons.layers_outlined,
      iconColor: Color(0xFF60A5FA),  // blue-400
      bgColor: Color(0x1A3B82F6),
      borderColor: Color(0x333B82F6),
      pillBg: Color(0x263B82F6),
      pillText: Color(0xFF93C5FD),
    ),
    _VcStyle(
      iconData: Icons.bolt_outlined,
      iconColor: Color(0xFFA78BFA),  // purple-400
      bgColor: Color(0x1A8B5CF6),
      borderColor: Color(0x338B5CF6),
      pillBg: Color(0x268B5CF6),
      pillText: Color(0xFFC4B5FD),
    ),
    _VcStyle(
      iconData: Icons.trending_up,
      iconColor: Color(0xFF34D399),  // emerald-400
      bgColor: Color(0x1A10B981),
      borderColor: Color(0x3310B981),
      pillBg: Color(0x2610B981),
      pillText: Color(0xFF6EE7B7),
    ),
  ];

  Widget _buildVcGroup(Map group, int idx) {
    final style = _vcStyles[idx.clamp(0, 2)];
    final title = group['title'] as String? ?? '';
    final note = group['note'] as String? ?? '';
    final keyCount = group['key_count'] as int? ?? 0;
    final keys = (group['keys'] as List?) ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.bgColor,
            border: Border.all(color: style.borderColor),
          ),
          child: Icon(style.iconData, size: 18, color: style.iconColor),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: style.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary)),
                  ),
                  Text('$keyCount yếu tố',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.darkTextMuted)),
                ]),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                ],
                if (keys.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final k in keys)
                        _buildKeyPills(k as Map, style),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPills(Map key, _VcStyle style) {
    final rootTitle = key['title'] as String? ?? '';
    final children = (key['children'] as List?) ?? [];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Root pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: style.pillBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.borderColor),
          ),
          child: Text(rootTitle,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: style.pillText)),
        ),
        // Arrow + child pills
        if (children.isNotEmpty) ...[
          Text('›',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.darkTextMuted.withValues(alpha: 0.5))),
          for (final c in children)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: style.pillBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: style.borderColor),
              ),
              child: Text((c as Map)['title'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: style.pillText.withValues(alpha: 0.8))),
            ),
        ],
      ],
    );
  }

  Widget _buildChartMeta(Map ch) {
    final breadcrumb = ch['breadcrumb'] as String? ?? '';
    final latestDate = ch['latest_date'] as String? ?? '';
    final corr = ch['correlation'] as String? ?? 'none';

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (breadcrumb.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_open_outlined,
                size: 11, color: AppColors.darkTextMuted),
            const SizedBox(width: 3),
            Text(breadcrumb,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
        if (latestDate.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time,
                size: 11, color: AppColors.darkTextMuted),
            const SizedBox(width: 3),
            Text('Cập nhật: $latestDate',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
        if (corr == 'positive')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Thuận chiều',
                style: TextStyle(fontSize: 9, color: AppColors.successDark)),
          )
        else if (corr == 'negative')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dangerDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Nghịch chiều',
                style: TextStyle(fontSize: 9, color: AppColors.dangerDark)),
          ),
      ],
    );
  }

  Widget _buildEcoChart(Map ch) {
    final data = (ch['data'] as Map?) ?? {};
    final labels = (data['labels'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [];
    final datasets = (data['datasets'] as List?) ?? [];
    if (datasets.isEmpty || labels.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Không có dữ liệu biểu đồ',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
        ),
      );
    }

    final ds0 = datasets[0] as Map;
    final ds1 = datasets.length > 1 ? datasets[1] as Map : null;
    final vals0 = (ds0['values'] as List?) ?? [];
    final vals1 = ds1 != null ? (ds1['values'] as List?) ?? [] : <dynamic>[];

    // Filter by period
    final cutoff = _chartPeriodDays < 0
        ? null
        : DateTime.now().subtract(Duration(days: _chartPeriodDays));

    final filteredLabels = <String>[];
    final filtered0 = <double>[];
    final filtered1 = <double?>[];

    for (int i = 0; i < labels.length; i++) {
      if (i >= vals0.length) break;
      final dt = DateTime.tryParse(labels[i]);
      if (dt == null) continue;
      if (cutoff != null && dt.isBefore(cutoff)) continue;
      final v0 = vals0[i];
      if (v0 == null) continue;
      filteredLabels.add(labels[i]);
      filtered0.add((v0 as num).toDouble());
      if (i < vals1.length && vals1[i] != null) {
        filtered1.add((vals1[i] as num).toDouble());
      } else {
        filtered1.add(null);
      }
    }

    if (filtered0.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Không có dữ liệu trong khoảng thời gian này',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
        ),
      );
    }

    final n = filtered0.length;
    final spots0 = [for (int i = 0; i < n; i++) FlSpot(i.toDouble(), filtered0[i])];
    final hasStock = filtered1.any((v) => v != null);
    final spots1 = hasStock
        ? [
            for (int i = 0; i < n; i++)
              if (filtered1[i] != null) FlSpot(i.toDouble(), filtered1[i]!)
          ]
        : <FlSpot>[];

    // Y ranges
    final min0 = filtered0.reduce((a, b) => a < b ? a : b);
    final max0 = filtered0.reduce((a, b) => a > b ? a : b);
    final pad0 = (max0 - min0).abs() * 0.15 + 0.001;

    final min1 = hasStock
        ? filtered1.whereType<double>().reduce((a, b) => a < b ? a : b)
        : 0.0;
    final max1 = hasStock
        ? filtered1.whereType<double>().reduce((a, b) => a > b ? a : b)
        : 1.0;
    final pad1 = (max1 - min1).abs() * 0.15 + 0.001;

    // X label helper — pick ~5 evenly spaced
    String xLabel(String iso) {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString().substring(2);
      return '$m/$y';
    }

    const double leftReserved = 46;
    const double rightReserved = 46;
    const double bottomReserved = 22;

    // Primary indicator line chart
    final primary = LineChartData(
      minX: 0,
      maxX: (n - 1).toDouble(),
      minY: min0 - pad0,
      maxY: max0 + pad0,
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
              if (v == meta.max || v == meta.min) {
                return const SizedBox.shrink();
              }
              final s = v.abs() >= 10000
                  ? '${(v / 1000).toStringAsFixed(0)}k'
                  : v.abs() >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : v.toStringAsFixed(1);
              return Text(s,
                  style: const TextStyle(
                      color: AppColors.darkTextMuted, fontSize: 9));
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: hasStock ? rightReserved : 8,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReserved,
            getTitlesWidget: (v, _) {
              final i = v.round();
              if (i < 0 || i >= filteredLabels.length) {
                return const SizedBox.shrink();
              }
              // Show ~5 labels
              final step = (n / 5).ceil().clamp(1, n);
              if (i % step != 0 && i != n - 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(xLabel(filteredLabels[i]),
                    style: const TextStyle(
                        color: AppColors.darkTextMuted, fontSize: 9)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots0,
          isCurved: true,
          color: AppColors.brandPrimaryDark,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.brandPrimaryDark.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.darkSurface,
          getTooltipItems: (spots) => spots.map((s) {
            final i = s.x.round().clamp(0, filteredLabels.length - 1);
            return LineTooltipItem(
              '${xLabel(filteredLabels[i])}\n${s.y.toStringAsFixed(2)}',
              const TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
    );

    // Stock price overlay (right axis)
    LineChartData? stockOverlay;
    if (hasStock && spots1.isNotEmpty) {
      stockOverlay = LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: min1 - pad1,
        maxY: max1 + pad1,
        backgroundColor: Colors.transparent,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles:
                  SideTitles(showTitles: false, reservedSize: leftReserved)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rightReserved,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                final s = v >= 1000
                    ? '${(v / 1000).toStringAsFixed(0)}k'
                    : v.toStringAsFixed(0);
                return Text(s,
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 9));
              },
            ),
          ),
          bottomTitles: const AxisTitles(
              sideTitles: SideTitles(
                  showTitles: false, reservedSize: bottomReserved)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots1,
            isCurved: true,
            color: AppColors.darkTextMuted,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            dashArray: [4, 3],
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      );
    }

    // Legend row
    final ds0Title = ds0['title'] as String? ?? 'Chỉ số';
    final ds1Title = ds1?['title'] as String? ?? 'Giá CP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _LegendDot(color: AppColors.brandPrimaryDark, label: ds0Title),
          if (hasStock) ...[
            const SizedBox(width: 12),
            _LegendDot(
                color: AppColors.darkTextMuted, label: ds1Title, line: true),
          ],
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              LineChart(primary),
              if (stockOverlay != null) LineChart(stockOverlay),
            ],
          ),
        ),
      ],
    );
  }

}
