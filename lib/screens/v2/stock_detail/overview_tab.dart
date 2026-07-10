part of '../stock_detail_screen_v2.dart';

/// Tab 1: Tổng quan — giá, biểu đồ giá, thẻ Cơ hội & Rủi ro.
extension on _StockDetailScreenV2State {
  // ---------- Tab 1: Tổng quan ----------
  Widget _buildOverview() {
    const ranges = ['1y', '3m', '6m', '3y', '5y'];
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Biểu đồ giá', style: text.titleMedium),
                    const Spacer(),
                    for (final r in ranges) ...[
                      _RangePill(
                        label: r.toUpperCase(),
                        active: _priceRange == r,
                        onTap: () {
                          _rebuild(() => _priceRange = r);
                          _loadRatio();
                        },
                      ),
                      if (r != ranges.last) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 240, child: _buildPriceChart()),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.darkBorder),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 6,
                  children: [
                    const _LegendDot(
                        color: AppColors.brandPrimaryDark,
                        label: 'Giá đóng cửa'),
                    if (_toD(_overview?['avg_target_price']) != null)
                      _LegendDot(
                          color: Colors.orangeAccent,
                          label: 'Định giá TB${(_overview?['valuation_date']?.toString() ?? '').isNotEmpty ? ' (${_overview?['valuation_date']})' : ''}'),
                    if ((_technical?['data'] as Map?)?['levels']?['nearest_support'] != null)
                      const _LegendDot(
                          color: AppColors.successDark,
                          label: 'Hỗ trợ (HT)'),
                    if ((_technical?['data'] as Map?)?['levels']?['nearest_resistance'] != null)
                      const _LegendDot(
                          color: Colors.redAccent,
                          label: 'Kháng cự (KC)'),
                    if (_signals.isNotEmpty)
                      const _LegendDot(
                          color: AppColors.successDark,
                          label: 'Điểm theo dõi mua ▲'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildOpportunityRiskCard(),
        ],
      ),
    );
  }

  Widget _buildOpportunityRiskCard() {
    if (_loadingOverview) {
      return const FwSkeleton(height: 140, radius: AppRadius.lg);
    }
    if (_errOverview != null && _overview == null) {
      return _SectionError(
          message: 'Không tải được tổng quan', onRetry: _loadOverview);
    }
    final o = _overview;
    if (o == null) return const SizedBox.shrink();

    final faScore = _toD(o['fa_score'] ?? o['wealth_fa']) ?? 0.0;

    double upside = 0.0;
    bool valuationReady = !_loadingValuation && _valuation != null;
    if (valuationReady) {
      final price = _toD(o['price']) ?? 0.0;
      final details = (_valuation!['details'] as List<dynamic>?) ?? [];
      if (details.isNotEmpty && price > 0) {
        final targets = details
            .map((d) => _toD((d as Map)['target_price']))
            .whereType<double>()
            .toList();
        if (targets.isNotEmpty) {
          final avg = targets.reduce((a, b) => a + b) / targets.length;
          upside = (avg / price - 1) * 100;
        }
      }
    }

    double opp = (50 + faScore).clamp(0, 90);
    if (valuationReady && upside < 0) {
      opp -= upside.abs().clamp(0, 25);
    }
    opp = opp.clamp(10, 90);
    final risk = 100 - opp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: _OpportunityRiskCard(
        opportunity: opp,
        risk: risk,
        faScore: faScore,
        upside: valuationReady ? upside : null,
        insight: _insight,
      ),
    );
  }

}
