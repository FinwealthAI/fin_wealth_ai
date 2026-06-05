import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/api_config.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import 'margin_screen_v2.dart';
import 'stock_detail_screen_v2.dart';

/// Màn "Quản lý danh mục" — liệt kê các danh mục đã lưu (UserMarginProfile)
/// kèm NAV, tiền mặt, MR và các mã đang nắm. Bám section "accounts" của
/// sidebar Super Broker (`/api/super-broker/portfolio/`).
///
/// Chỉnh sửa chi tiết (thêm/bớt mã, tiền mặt, ký quỹ) thực hiện trong
/// Trình giả lập Margin ([MarginScreenV2]).
class PortfolioListScreenV2 extends StatefulWidget {
  const PortfolioListScreenV2({super.key});

  @override
  State<PortfolioListScreenV2> createState() => _PortfolioListScreenV2State();
}

class _PortfolioListScreenV2State extends State<PortfolioListScreenV2> {
  List<_Account> _accounts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Dio _dio() {
    final auth = context.read<AuthRepository>();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        if (auth.accessToken != null)
          'Authorization': 'Bearer ${auth.accessToken}',
      },
    ));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio().get('/api/super-broker/portfolio/');
      final raw = (resp.data?['accounts'] as List?) ?? const [];
      final accounts = raw
          .whereType<Map>()
          .map((e) => _Account.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh mục.';
        _loading = false;
      });
    }
  }

  Future<void> _openMarginSimulator() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MarginScreenV2()),
    );
    if (mounted) _load(); // làm mới khi quay lại (có thể vừa lưu danh mục)
  }

  void _openTicker(String ticker) {
    if (ticker.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StockDetailScreenV2(ticker: ticker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: 'Quản lý danh mục',
        subtitle: _loading ? null : '${_accounts.length} danh mục',
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Trình giả lập Margin',
            onPressed: _openMarginSimulator,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary));
    }
    if (_error != null) {
      return _emptyState(
        icon: Icons.cloud_off,
        title: _error!,
        actionLabel: 'Thử lại',
        onAction: _load,
      );
    }
    if (_accounts.isEmpty) {
      return _emptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Chưa có danh mục nào',
        subtitle:
            'Tạo danh mục trong Trình giả lập Margin để theo dõi NAV và rủi ro ký quỹ.',
        actionLabel: 'Mở giả lập Margin',
        onAction: _openMarginSimulator,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _accounts.length,
      itemBuilder: (_, i) => _AccountCard(
        account: _accounts[i],
        onOpenTicker: _openTicker,
        onEdit: _openMarginSimulator,
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: AppColors.darkTextMuted),
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 13)),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: Text(actionLabel),
              onPressed: onAction,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Card 1 danh mục ──────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final _Account account;
  final void Function(String ticker) onOpenTicker;
  final VoidCallback onEdit;
  const _AccountCard({
    required this.account,
    required this.onOpenTicker,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.darkTextMuted),
                tooltip: 'Chỉnh sửa trong giả lập Margin',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Tài sản ròng (NAV)',
              style: TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(_fmtVnd(account.nav),
              style: const TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _stat('Tiền mặt', _fmtVnd(account.cash)),
              const SizedBox(width: AppSpacing.lg),
              _stat('Số mã', '${account.totalTickers}'),
              const Spacer(),
              if (account.mmRatio > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('MM ${account.mmRatio.round()}%',
                      style: const TextStyle(
                          color: AppColors.warningDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (account.holdings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: account.holdings
                  .map((h) => _HoldingChip(
                        ticker: h.ticker,
                        onTap: () => onOpenTicker(h.ticker),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.darkTextMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _HoldingChip extends StatelessWidget {
  final String ticker;
  final VoidCallback onTap;
  const _HoldingChip({required this.ticker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Text(ticker,
            style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Account {
  final int id;
  final String name;
  final double cash;
  final double nav;
  final double mmRatio;
  final int totalTickers;
  final List<_Holding> holdings;

  _Account({
    required this.id,
    required this.name,
    required this.cash,
    required this.nav,
    required this.mmRatio,
    required this.totalTickers,
    required this.holdings,
  });

  factory _Account.fromJson(Map<String, dynamic> j) {
    final rawH = (j['holdings'] as List?) ?? const [];
    return _Account(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name']?.toString() ?? 'Danh mục',
      cash: (j['cash'] as num?)?.toDouble() ?? 0,
      nav: (j['nav'] as num?)?.toDouble() ?? 0,
      mmRatio: (j['mm_ratio'] as num?)?.toDouble() ?? 0,
      totalTickers: (j['total_tickers'] as num?)?.toInt() ?? rawH.length,
      holdings: rawH
          .whereType<Map>()
          .map((e) => _Holding.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class _Holding {
  final String ticker;
  final double q;
  final double avgCost;
  _Holding({required this.ticker, required this.q, required this.avgCost});

  factory _Holding.fromJson(Map<String, dynamic> j) => _Holding(
        ticker: (j['ticker']?.toString() ?? '').toUpperCase(),
        q: (j['q'] as num?)?.toDouble() ?? 0,
        avgCost: (j['avg_cost'] as num?)?.toDouble() ?? 0,
      );
}

String _fmtVnd(double v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$buf đ';
}
