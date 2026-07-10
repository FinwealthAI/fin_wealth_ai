part of '../stock_detail_screen_v2.dart';

/// Tab 4: Sức khỏe tài chính — tăng trưởng + an toàn tài chính.
extension on _StockDetailScreenV2State {
  // ---------- Tab 4: Sức khỏe TC ----------
  Widget _buildHealth() {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () async => Future.wait([_loadGrowth(), _loadSafety()]),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + toggle
                Row(
                  children: [
                    Text('Doanh thu & Lợi nhuận', style: text.titleMedium),
                    const Spacer(),
                    _PeriodToggle(
                      value: _growthPeriod,
                      onChanged: (p) => _loadGrowth(p),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Legend
                Row(children: [
                  const _LegendDot(color: AppColors.brandSecondaryDark, label: 'DT'),
                  const SizedBox(width: 8),
                  const _LegendDot(color: AppColors.successDark, label: 'LN'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.brandSecondaryDark.withValues(alpha: 0.6), label: '%DT', line: true),
                  const SizedBox(width: 8),
                  _LegendDot(color: AppColors.successDark.withValues(alpha: 0.6), label: '%LN', line: true),
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildGrowthChart(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSafetyCard(),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    final text = Theme.of(context).textTheme;
    if (_loadingSafety) {
      return const FwSkeleton(height: 220, radius: AppRadius.lg);
    }
    if (_errSafety != null && _safety == null) {
      return _SectionError(
          message: 'Không tải được sức khỏe tài chính',
          onRetry: _loadSafety);
    }
    final s = _safety;
    if (s == null) return const SizedBox.shrink();

    final ratios = <(String, String?, Color)>[
      ('ROE', _fmtPct(s['roe']), AppColors.successDark),
      ('ROA', _fmtPct(s['roaa']), AppColors.successDark),
      ('Nợ/VCSH',
          _fmtNum(s['debt_to_equity_latest']), AppColors.brandSecondaryDark),
      ('KN trả lãi',
          _fmtNum(s['interest_coverage']), AppColors.successDark),
      ('CFO/DT', _fmtPct(s['cfo_to_revenue_latest']),
          AppColors.brandSecondaryDark),
      ('CPS', _fmtNum(s['cps'], dec: 0), AppColors.warningDark),
    ];
    final cf = (s['cashflow'] as Map?) ?? const {};

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.darkTextSecondary),
                const SizedBox(width: 6),
                Text('Chỉ số cốt lõi', style: text.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            children: [
              for (final r in ratios)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.darkBorder),
                      bottom: BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.$1,
                          style: text.labelSmall?.copyWith(
                              color: AppColors.darkTextMuted)),
                      const SizedBox(height: 2),
                      Text(r.$2 ?? '—',
                          style: text.titleSmall?.copyWith(color: r.$3)),
                    ],
                  ),
                ),
            ],
          ),
          if (cf.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Dòng tiền (Tỷ VNĐ)',
                  style: text.titleSmall),
            ),
            for (final entry in cf.entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_cfLabel(entry.key.toString()),
                          style: text.bodySmall),
                    ),
                    Text(
                      entry.value == null
                          ? '—'
                          : (entry.value as num).toStringAsFixed(1),
                      style: text.titleSmall,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  static String _cfLabel(String key) => switch (key) {
        'cfo' => 'CFO',
        'cfi' => 'CFI',
        'dividends' => 'Cổ tức trả CSH',
        _ => key,
      };

  static String? _fmtPct(dynamic v) {
    final d = _toD(v);
    return d == null ? null : '${d.toStringAsFixed(1)}%';
  }

  static String? _fmtNum(dynamic v, {int dec = 2}) {
    final d = _toD(v);
    if (d == null) return null;
    final fmt = NumberFormat('#,##0${dec > 0 ? '.${'0' * dec}' : ''}', 'vi_VN');
    return fmt.format(d);
  }

}
