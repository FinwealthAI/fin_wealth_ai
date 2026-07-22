part of '../stock_detail_screen_v2.dart';

/// Tab: Dự báo — dự báo xu hướng giá bằng mô hình AI (Kronos).
///
/// Nguồn dữ liệu: GET `/api/forecast/<ticker>/` (xem
/// `../finwealth/price_forecast/views.py` → `forecast_api`). Mã ngoài universe /
/// chưa có dự báo → backend trả `{success:false}` → hiển thị empty state.
extension on _StockDetailScreenV2State {
  Widget _buildForecast() {
    if (_loadingForecast) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          FwSkeleton(height: 190, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          FwSkeleton(height: 200, radius: AppRadius.lg),
        ],
      );
    }
    if (_errForecast != null && _forecast == null) {
      return _SectionError(
          message: 'Không tải được dự báo', onRetry: _loadForecast);
    }

    final f = _forecast;
    final ok = f != null && f['success'] == true && f['prob_up'] != null;
    if (!ok) {
      return RefreshIndicator(
        onRefresh: _loadForecast,
        color: AppColors.brandPrimary,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: FwEmptyState(
                icon: Icons.insights_outlined,
                title: 'Chưa có dự báo cho mã này',
                message:
                    'Dự báo xu hướng giá (AI) chỉ có cho nhóm cổ phiếu trong phạm vi theo dõi.',
              ),
            ),
          ],
        ),
      );
    }

    final scenarios = (f['forecast'] is Map &&
            (f['forecast'] as Map)['scenarios'] is List)
        ? List<Map>.from(((f['forecast'] as Map)['scenarios'] as List)
            .whereType<Map>())
        : const <Map>[];

    return RefreshIndicator(
      onRefresh: _loadForecast,
      color: AppColors.brandPrimary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ForecastHeroCard(
            probUp: _toOptD(f['prob_up']),
            expectedReturn: _toOptD(f['expected_return']),
            horizonDays: (f['horizon_days'] as num?)?.toInt(),
            date: f['date'] as String?,
            modelTag: f['model_tag'] as String?,
          ),
          if (scenarios.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ForecastScenariosCard(scenarios: scenarios),
          ],
          const SizedBox(height: AppSpacing.md),
          const _ForecastDisclaimer(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ForecastHeroCard extends StatelessWidget {
  final double? probUp; // 0..1
  final double? expectedReturn; // 0..1
  final int? horizonDays;
  final String? date;
  final String? modelTag;
  const _ForecastHeroCard({
    required this.probUp,
    required this.expectedReturn,
    required this.horizonDays,
    required this.date,
    required this.modelTag,
  });

  @override
  Widget build(BuildContext context) {
    final probPct = ((probUp ?? 0) * 100).round();
    final probColor =
        probPct >= 50 ? AppColors.successDark : AppColors.dangerDark;
    final expPct = (expectedReturn ?? 0) * 100;
    final expColor =
        expPct >= 0 ? AppColors.successDark : AppColors.dangerDark;

    return FwCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_graph, size: 15, color: AppColors.brandPrimaryDark),
          const SizedBox(width: 6),
          Text('Dự báo xu hướng', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (horizonDays != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$horizonDays phiên tới',
                  style: const TextStyle(
                      color: AppColors.brandPrimaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Xác suất tăng giá',
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text('$probPct%',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: probColor)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('LN kỳ vọng',
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(expPct >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18, color: expColor),
              const SizedBox(width: 4),
              Text('${expPct >= 0 ? '+' : ''}${expPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: expColor)),
            ]),
          ]),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (probPct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.dangerDark.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(probColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Giảm', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10)),
          const Spacer(),
          const Text('Tăng', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10)),
        ]),
        if (date != null || modelTag != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.darkTextMuted),
            const SizedBox(width: 4),
            Text(_asOf(date),
                style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
            const Spacer(),
            if (modelTag != null)
              Text(modelTag!,
                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10)),
          ]),
        ],
      ]),
    );
  }

  String _asOf(String? d) {
    if (d == null) return '';
    final parts = d.split('-'); // YYYY-MM-DD
    return parts.length == 3 ? 'Tính đến ${parts[2]}/${parts[1]}' : '';
  }
}

class _ForecastScenariosCard extends StatelessWidget {
  final List<Map> scenarios;
  const _ForecastScenariosCard({required this.scenarios});

  @override
  Widget build(BuildContext context) {
    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.alt_route, size: 14, color: AppColors.brandSecondaryDark),
            const SizedBox(width: 6),
            Text('Kịch bản giá', style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        for (int i = 0; i < scenarios.length; i++) ...[
          _ForecastScenarioTile(scenario: scenarios[i]),
          if (i != scenarios.length - 1)
            const Divider(height: 1, color: AppColors.darkBorder, indent: 16, endIndent: 16),
        ],
      ]),
    );
  }
}

class _ForecastScenarioTile extends StatelessWidget {
  final Map scenario;
  const _ForecastScenarioTile({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final label = scenario['label'] as String? ?? 'Kịch bản';
    final prob = ((_toOptD(scenario['prob']) ?? 0) * 100).round();
    final ret = (_toOptD(scenario['avg_return']) ?? 0) * 100;
    final targetK = _toOptD(scenario['target']);
    final up = ret >= 0;
    final color = up ? AppColors.successDark : AppColors.dangerDark;
    final targetVnd = targetK != null
        ? NumberFormat('#,##0', 'vi_VN').format(targetK * 1000)
        : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$prob%',
                  style: const TextStyle(
                      color: AppColors.brandPrimaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(targetVnd,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          Text('${up ? '+' : ''}${ret.toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _ForecastDisclaimer extends StatelessWidget {
  const _ForecastDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, size: 13, color: AppColors.darkTextMuted),
      const SizedBox(width: 6),
      const Expanded(
        child: Text(
          'Dự báo do mô hình AI sinh ra dựa trên dữ liệu quá khứ, chỉ mang tính tham khảo, không phải khuyến nghị đầu tư.',
          style: TextStyle(color: AppColors.darkTextMuted, fontSize: 11, height: 1.4),
        ),
      ),
    ]);
  }
}
