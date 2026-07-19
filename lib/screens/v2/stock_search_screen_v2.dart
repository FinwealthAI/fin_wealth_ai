import 'package:flutter/material.dart';
import '../../models/stock_models.dart';
import '../../theme/theme.dart';
import 'stock_detail_screen_v2.dart';

class StockSearchScreenV2 extends StatefulWidget {
  const StockSearchScreenV2({super.key});

  @override
  State<StockSearchScreenV2> createState() => _StockSearchScreenV2State();
}

class _StockSearchScreenV2State extends State<StockSearchScreenV2> {
  final TextEditingController _q = TextEditingController();
  String _query = '';

  // Không tải trước danh sách để tăng tốc độ mở màn hình search;
  // người dùng gõ mã và nhấn Enter để mở trực tiếp.
  final List<StockValuation> _all = const [];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _open(String ticker) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => StockDetailScreenV2(ticker: ticker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toUpperCase();
    final results = q.isEmpty
        ? _all.take(50).toList()
        : _all.where((t) => t.ticker.contains(q)).toList();

    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _q,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm theo mã cổ phiếu…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _q.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (v) {
            final upper = v.trim().toUpperCase();
            if (upper.isNotEmpty) _open(upper);
          },
        ),
      ),
      body: _buildBody(results, q, text),
    );
  }

  Widget _buildBody(
      List<StockValuation> results, String q, TextTheme text) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off,
                  size: 36, color: AppColors.darkTextMuted),
              const SizedBox(height: AppSpacing.sm),
              Text('Không tìm thấy mã phù hợp', style: text.bodyMedium),
              const SizedBox(height: 4),
              Text('Nhấn Enter để mở mã “${q.isEmpty ? '...' : q}”',
                  style: text.labelSmall),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 64, color: AppColors.darkBorder),
      itemBuilder: (ctx, i) {
        final t = results[i];
        final priceLabel = t.investPrice > 0
            ? 'Giá ${t.investPrice.toStringAsFixed(0)}'
            : '';
        final upside = t.valuationDifference;
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              t.ticker,
              style: const TextStyle(
                color: AppColors.brandPrimaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(t.ticker,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            priceLabel.isEmpty ? '—' : priceLabel,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (upside != 0)
                Text(
                  '${upside > 0 ? '+' : ''}${upside.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: upside >= 0
                        ? AppColors.successDark
                        : AppColors.dangerDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppColors.darkTextMuted),
            ],
          ),
          onTap: () => _open(t.ticker),
        );
      },
    );
  }
}
