part of '../stock_detail_screen_v2.dart';

/// Tab 2: Định giá — biểu đồ PE/PB, bảng khuyến nghị CTCK.
extension on _StockDetailScreenV2State {
  // ---------- Tab 2: Định giá ----------
  Widget _buildValuation() {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _loadValuation,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Lịch sử định giá', style: text.titleMedium),
                    const Spacer(),
                    _RangePill(
                      label: 'P/E',
                      active: _valuationKind == 'PE',
                      onTap: () => _rebuild(() => _valuationKind = 'PE'),
                    ),
                    const SizedBox(width: 4),
                    _RangePill(
                      label: 'P/B',
                      active: _valuationKind == 'PB',
                      onTap: () => _rebuild(() => _valuationKind = 'PB'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 180, child: _buildValuationChart()),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                      color: _valuationKind == 'PE'
                          ? AppColors.brandPrimaryDark
                          : AppColors.brandSecondaryDark,
                      label: _valuationKind == 'PE' ? 'P/E' : 'P/B',
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const _LegendDot(
                      color: Colors.redAccent,
                      label: 'Trung bình 1 năm',
                      isDashed: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildBrokerTable(),
        ],
      ),
    );
  }

  Widget _buildBrokerTable() {
    final text = Theme.of(context).textTheme;
    if (_loadingValuation) {
      return const FwSkeleton(height: 200, radius: AppRadius.lg);
    }
    if (_errValuation != null && _valuation == null) {
      return _SectionError(
          message: 'Không tải được định giá', onRetry: _loadValuation);
    }
    final details =
        (_valuation?['details'] as List<dynamic>?) ?? const <dynamic>[];

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed,
                    size: 14, color: AppColors.darkTextSecondary),
                const SizedBox(width: 6),
                Text('Chi tiết định giá từ các CTCK',
                    style: text.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (details.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Chưa có khuyến nghị từ CTCK.',
                  style: text.bodySmall),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(flex: 4, child: _TableHead('Tổ chức')),
                  Expanded(
                      flex: 3,
                      child: _TableHead('Giá MT', alignRight: true)),
                  Expanded(
                      flex: 3,
                      child: _TableHead('Khuyến nghị', alignRight: true)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.darkBorder),
            for (final raw in details)
              _buildBrokerRow(raw as Map<String, dynamic>, text),
          ],
        ],
      ),
    );
  }

  Widget _buildBrokerRow(Map<String, dynamic> d, TextTheme text) {
    final firm = (d['firm_new'] ?? '').toString();
    final target = (d['target_price'] ?? '').toString();
    final rec = (d['recommendation'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Flexible(
                  child: FwBadge(
                    label: firm,
                    tone: FwBadgeTone.info,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('$target đ',
                textAlign: TextAlign.right, style: text.titleSmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              rec.isEmpty ? '—' : rec,
              textAlign: TextAlign.right,
              style: text.titleSmall?.copyWith(
                color: rec.toLowerCase().contains('mua')
                    ? AppColors.successDark
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
