import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late SearchStockRepository repo;
  bool _loading = true;
  List<dynamic> _items = [];
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    repo = context.read<SearchStockRepository>();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final resp = await repo.getUserNews();
      if (resp['success'] == true) {
        setState(() {
          _items = resp['news_items'] ?? [];
          _unread = resp['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông báo: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAll() async {
    try {
      await repo.markAllNotifications();
      await _fetchNotifications();
      // Pop về và truyền result true để Home biết cập nhật badge
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đánh dấu tất cả là đã đọc')),
      );
    }
  }

  Future<void> _markAsRead(int id, String? link) async {
    try {
      await repo.markNotification(id);
      if (link != null && link.isNotEmpty) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
      _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở thông báo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thông báo ($_unread chưa đọc)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        actions: [
          Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.done_all_rounded, color: theme.colorScheme.onSurface),
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: _markAll,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surfaceContainer.withOpacity(0.9),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchNotifications,
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có thông báo',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final bool isRead = n['is_read'] ?? false;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                                  theme.colorScheme.surfaceContainer.withOpacity(0.6),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? theme.colorScheme.outline.withOpacity(0.2)
                                      : theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRead
                                      ? Icons.notifications_none_outlined
                                      : Icons.notifications_active_rounded,
                                  color: isRead
                                      ? theme.colorScheme.outline
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                n['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '${n['date'] ?? ''}\n${n['content'] ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              isThreeLine: true,
                              onTap: () => _markAsRead(n['id'], n['link']),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
