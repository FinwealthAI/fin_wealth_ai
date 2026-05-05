import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/search_stock_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import 'stock_detail_screen_v2.dart';

enum NotifKind { signal, report, ai, price, system, blog }

class NotifItem {
  final int id;
  final NotifKind kind;
  final String title;
  final String body;
  final String time;
  final String? ticker;
  final String? link;
  final bool unread;

  const NotifItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.ticker,
    this.link,
    this.unread = false,
  });

  NotifItem copyWith({bool? unread}) => NotifItem(
        id: id,
        kind: kind,
        title: title,
        body: body,
        time: time,
        ticker: ticker,
        link: link,
        unread: unread ?? this.unread,
      );

  factory NotifItem.fromApi(Map<String, dynamic> j) {
    final src = (j['source'] as String? ?? 'SYSTEM').toUpperCase();
    final kind = switch (src) {
      'BLOG' => NotifKind.blog,
      'REPORT' => NotifKind.report,
      'SIGNAL' => NotifKind.signal,
      'AI' => NotifKind.ai,
      'PRICE' => NotifKind.price,
      _ => NotifKind.system,
    };
    final title = j['title'] as String? ?? '';
    final ticker = _extractTicker(title);
    return NotifItem(
      id: j['id'] as int,
      kind: kind,
      title: title,
      body: j['content'] as String? ?? '',
      time: j['date'] as String? ?? '',
      ticker: ticker,
      link: j['link'] as String?,
      unread: !(j['is_read'] as bool? ?? false),
    );
  }

  static String? _extractTicker(String title) {
    final m = RegExp(r'\b([A-Z]{3})\b').firstMatch(title);
    return m?.group(1);
  }
}

class NotificationsScreenV2 extends StatefulWidget {
  const NotificationsScreenV2({super.key});

  @override
  State<NotificationsScreenV2> createState() => _NotificationsScreenV2State();
}

class _NotificationsScreenV2State extends State<NotificationsScreenV2> {
  late final SearchStockRepository _repo =
      context.read<SearchStockRepository>();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  int _filter = 0;
  List<NotifItem> _items = const [];
  bool _loading = true;
  Object? _err;

  static const _filters = [
    'Tất cả',
    'Chưa đọc',
    'Tín hiệu',
    'Báo cáo',
    'AI',
    'Hệ thống',
  ];

  @override
  void initState() {
    super.initState();
    if (_authRepo.accessToken != null) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final data = await _repo.getUserNews();
      final raw = (data['news_items'] as List<dynamic>?) ?? [];
      final items = raw
          .map((e) => NotifItem.fromApi(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e;
        _loading = false;
      });
    }
  }

  List<NotifItem> get _visible {
    return _items.where((n) {
      switch (_filter) {
        case 0:
          return true;
        case 1:
          return n.unread;
        case 2:
          return n.kind == NotifKind.signal;
        case 3:
          return n.kind == NotifKind.report;
        case 4:
          return n.kind == NotifKind.ai;
        case 5:
          return n.kind == NotifKind.system;
        default:
          return true;
      }
    }).toList();
  }

  int get _unreadCount => _items.where((n) => n.unread).length;

  Future<void> _markAllRead() async {
    setState(() {
      _items = _items.map((n) => n.copyWith(unread: false)).toList();
    });
    try {
      await _repo.markAllNotifications();
    } catch (_) {}
  }

  Future<void> _markRead(int id) async {
    setState(() {
      _items = [
        for (final n in _items) n.id == id ? n.copyWith(unread: false) : n,
      ];
    });
    try {
      await _repo.markNotification(id);
    } catch (_) {}
  }

  void _openItem(NotifItem n) {
    if (n.unread) _markRead(n.id);
    if (n.ticker != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => StockDetailScreenV2(ticker: n.ticker!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authRepo.accessToken == null;
    final visible = _visible;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_unreadCount > 0 && !isGuest)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Đã đọc'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandPrimaryDark,
              ),
            ),
        ],
      ),
      body: isGuest
          ? Center(
              child: FwEmptyState(
                icon: Icons.lock_outline,
                title: 'Đăng nhập để xem thông báo',
                action: FwButton(
                  label: 'Đăng nhập',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/login-v2'),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  FwFilterPillBar(
                    items: _filters,
                    activeIndex: _filter,
                    onChanged: (i) => setState(() => _filter = i),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: _buildBody(visible, text),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody(List<NotifItem> visible, TextTheme text) {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 92, radius: AppRadius.lg),
      );
    }
    if (_err != null) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được thông báo',
          message: _err.toString().replaceFirst('Exception: ', ''),
          action: FwButton(label: 'Thử lại', onPressed: _load),
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined,
                  size: 36, color: AppColors.darkTextMuted),
              const SizedBox(height: AppSpacing.sm),
              Text('Không có thông báo', style: text.bodyMedium),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) => _NotifTile(
        item: visible[i],
        onTap: () => _openItem(visible[i]),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotifItem item;
  final VoidCallback? onTap;
  const _NotifTile({required this.item, this.onTap});

  (IconData, Color) _icon() {
    switch (item.kind) {
      case NotifKind.signal:
        return (Icons.bolt, AppColors.successDark);
      case NotifKind.report:
        return (Icons.description_outlined, AppColors.brandSecondaryDark);
      case NotifKind.ai:
        return (Icons.auto_awesome, AppColors.brandPrimaryDark);
      case NotifKind.price:
        return (Icons.notifications_active_outlined, AppColors.warningDark);
      case NotifKind.blog:
        return (Icons.menu_book_outlined, AppColors.brandSecondaryDark);
      case NotifKind.system:
        return (Icons.settings_outlined, AppColors.darkTextSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, color) = _icon();
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: item.unread
                  ? color.withValues(alpha: 0.35)
                  : AppColors.darkBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title,
                              style: text.titleSmall?.copyWith(
                                fontWeight: item.unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (item.unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.brandPrimaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.ticker != null) ...[
                          FwBadge(
                            label: item.ticker!,
                            tone: FwBadgeTone.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(item.time, style: text.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
