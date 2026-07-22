part of '../stock_detail_screen_v2.dart';

/// Tab 5: Định lượng — điểm Wealth/FA/TA.
extension on _StockDetailScreenV2State {
  // ---------- Tab 5: Định lượng ----------
  Widget _buildQuant() {
    if (_loadingQuant) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          FwSkeleton(height: 110, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          FwSkeleton(height: 160, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          FwSkeleton(height: 160, radius: AppRadius.lg),
        ],
      );
    }
    if (_errQuant != null && _quant == null) {
      return _SectionError(message: 'Không tải được dữ liệu định lượng', onRetry: _loadQuant);
    }

    final q = _quant;
    if (q == null) {
      return const Center(
        child: Text('Chưa có dữ liệu định lượng', style: TextStyle(color: AppColors.darkTextMuted)),
      );
    }

    final wealth = q['wealth'] as Map? ?? {};
    final fa = q['fa'] as Map? ?? {};
    final ta = q['ta'] as Map? ?? {};
    // Điểm alpha factor (Alpha Zoo) — null khi mã ngoài universe Top-200.
    final factors = q['factors'] as Map?;

    return RefreshIndicator(
      onRefresh: _loadQuant,
      color: AppColors.brandPrimary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _QuantWealthCard(wealth: wealth),
          const SizedBox(height: AppSpacing.lg),
          _QuantFaCard(fa: fa),
          const SizedBox(height: AppSpacing.lg),
          _QuantTaCard(ta: ta),
          if (factors != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _QuantAlphaCard(factors: factors),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

}
