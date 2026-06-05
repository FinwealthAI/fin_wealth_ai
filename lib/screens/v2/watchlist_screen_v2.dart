import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/watchlist_item.dart';
import '../../respositories/watchlist_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/watchlist_row.dart';
import 'stock_detail_screen_v2.dart';

/// Màn "Danh sách theo dõi" — quản lý các mã đang theo dõi (WatchlistStockUser).
/// Bám sidebar watchlist của trang `/agent/` web nhưng dùng dữ liệu giàu hơn
/// (giá, FA/TA) từ `WatchlistRepository`.
class WatchlistScreenV2 extends StatefulWidget {
  const WatchlistScreenV2({super.key});

  @override
  State<WatchlistScreenV2> createState() => _WatchlistScreenV2State();
}

class _WatchlistScreenV2State extends State<WatchlistScreenV2> {
  late final WatchlistRepository _repo = context.read<WatchlistRepository>();

  List<WatchlistItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getWatchlist();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách theo dõi.';
        _loading = false;
      });
    }
  }

  Future<void> _remove(WatchlistItem item) async {
    // Optimistic remove — khôi phục nếu lỗi.
    final prev = _items;
    setState(() => _items = _items.where((e) => e.id != item.id).toList());
    try {
      await _repo.removeFromWatchlist(item.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = prev);
      _snack('Bỏ theo dõi thất bại, thử lại.');
    }
  }

  Future<void> _addDialog() async {
    final controller = TextEditingController();
    final ticker = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Thêm mã theo dõi',
            style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: AppColors.darkTextPrimary),
          decoration: const InputDecoration(hintText: 'VD: HPG'),
          onSubmitted: (v) => Navigator.pop(context, v.trim().toUpperCase()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().toUpperCase()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (ticker == null || ticker.isEmpty) return;
    try {
      await _repo.addToWatchlist(ticker);
      await _load();
      _snack('Đã thêm $ticker vào danh sách theo dõi.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _openDetail(WatchlistItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => StockDetailScreenV2(ticker: item.ticker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: 'Danh sách theo dõi',
        subtitle: _loading ? null : '${_items.length} mã',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mã',
            onPressed: _addDialog,
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
      return _centered(
        icon: Icons.cloud_off,
        title: _error!,
        actionLabel: 'Thử lại',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return _centered(
        icon: Icons.bookmark_border,
        title: 'Chưa theo dõi mã nào',
        subtitle: 'Thêm mã để theo dõi giá và tín hiệu FA/TA.',
        actionLabel: 'Thêm mã',
        onAction: _addDialog,
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        return WatchlistRow(
          ticker: item.ticker,
          price: item.currentPrice ?? 0,
          changePct: item.changePercent ?? 0,
          faTier: item.faTier,
          taTier: item.taTier,
          faLabel: item.faLabel,
          taLabel: item.taLabel,
          onTap: () => _openDetail(item),
          onRemove: () => _remove(item),
        );
      },
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      // ListView để RefreshIndicator vẫn kéo được khi rỗng.
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
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel),
              onPressed: onAction,
            ),
          ),
        ],
      ],
    );
  }
}
