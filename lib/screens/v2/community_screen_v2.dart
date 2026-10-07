import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/chat_history_service.dart';

const _avatarAsset = 'assets/images/mr_wealth_avatar.png';

/// Room "Cộng đồng Finwealth" — kênh bản tin chung do Mr. Wealth đăng, chỉ đọc.
/// Bám giao diện web (agent/static/dify/js/community.js): bong bóng kiểu chat,
/// ngăn cách theo ngày, like/dislike + copy dưới mỗi bài, rời/tham gia lại.
class CommunityScreenV2 extends StatefulWidget {
  final String? token;
  const CommunityScreenV2({super.key, required this.token});

  @override
  State<CommunityScreenV2> createState() => _CommunityScreenV2State();
}

class _CommunityScreenV2State extends State<CommunityScreenV2> {
  final ScrollController _scroll = ScrollController();
  CommunityFeed? _feed;
  bool _loading = true;
  bool _error = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final feed = await ChatHistoryService.fetchCommunityFeed(token: widget.token);
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
      if (feed.isMember) {
        ChatHistoryService.markCommunityRead(token: widget.token);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _toggleMembership() async {
    final feed = _feed;
    if (feed == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      await ChatHistoryService.setCommunityMembership(!feed.isMember,
          token: widget.token);
      await _load();
    } catch (_) {
      _snack('Không thực hiện được, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _rate(CommunityPost p, String rating) async {
    final feed = _feed;
    if (feed == null) return;
    final next = p.rating == rating ? null : rating;
    void apply(String? r) => setState(() {
          _feed = CommunityFeed(
            isMember: feed.isMember,
            unreadCount: feed.unreadCount,
            posts: [for (final x in _feed!.posts) x.id == p.id ? x.copyWith(rating: r) : x],
          );
        });
    apply(next);
    // Server chỉ nhận like/dislike; bỏ chọn chỉ là trạng thái cục bộ.
    if (next == null) return;
    try {
      await ChatHistoryService.sendCommunityFeedback(
          postId: p.id, rating: next, token: widget.token);
    } catch (_) {
      if (mounted) apply(p.rating);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (same(d, now)) return 'Hôm nay';
    if (same(d, now.subtract(const Duration(days: 1)))) return 'Hôm qua';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  static String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
                radius: 18, backgroundImage: AssetImage(_avatarAsset)),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cộng đồng Finwealth',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary)),
                  Text('Bản tin chung · chỉ đọc',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error || _feed == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lỗi khi tải Cộng đồng.',
                style: TextStyle(color: AppColors.danger, fontSize: 13)),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final feed = _feed!;
    if (!feed.isMember) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn đã rời Cộng đồng Finwealth.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary)),
              SizedBox(height: AppSpacing.xs),
              Text('Nhấn "Tham gia lại" bên dưới để tiếp tục nhận bản tin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
            ],
          ),
        ),
      );
    }
    if (feed.posts.isEmpty) {
      return const Center(
        child: Text('Chưa có bài đăng nào.',
            style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
      );
    }

    // Feed đã mới nhất trước. ListView `reverse: true` neo ở đáy nên mở lên là thấy
    // bài mới nhất (không cần jumpTo — extent ước lượng của list lười sẽ sai với bài
    // markdown dài). Trong list đảo, phần tử sau nằm PHÍA TRÊN → nhãn ngày đặt sau
    // bài đầu tiên của ngày đó (bài cũ nhất trong ngày).
    final posts = feed.posts;
    final children = <Widget>[];
    for (var i = 0; i < posts.length; i++) {
      final p = posts[i];
      final d = p.createdAt;
      children.add(_PostBubble(
        post: p,
        time: d == null ? '' : _time(d),
        onRate: (r) => _rate(p, r),
        onCopy: () {
          Clipboard.setData(ClipboardData(text: p.content));
          _snack('Đã sao chép');
        },
      ));
      final label = d == null ? null : _dayLabel(d);
      final nextDay = i + 1 < posts.length && posts[i + 1].createdAt != null
          ? _dayLabel(posts[i + 1].createdAt!)
          : null;
      if (label != null && label != nextDay) {
        children.add(_DaySeparator(label: label));
      }
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scroll,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: children,
      ),
    );
  }

  Widget _buildFooter() {
    final member = _feed?.isMember ?? true;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bản tin do Mr. Wealth đăng chung cho mọi nhà đầu tư. Đây là kênh ĐỌC — không trả lời tại đây.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.darkTextSecondary, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: _feed == null || _toggling ? null : _toggleMembership,
            child: Text(member ? 'Rời cộng đồng' : 'Tham gia lại'),
          ),
        ],
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  final String label;
  const _DaySeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkTextSecondary)),
        ),
      ),
    );
  }
}

class _PostBubble extends StatelessWidget {
  final CommunityPost post;
  final String time;
  final ValueChanged<String> onRate;
  final VoidCallback onCopy;

  const _PostBubble({
    required this.post,
    required this.time,
    required this.onRate,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
              radius: 14, backgroundImage: AssetImage(_avatarAsset)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border.all(color: AppColors.darkBorder),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(post.title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkTextPrimary,
                                  height: 1.4)),
                        ),
                      MarkdownBody(
                        data: post.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkTextPrimary,
                              height: 1.5),
                          blockquote: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkTextSecondary),
                        ),
                        onTapLink: (text, href, title) {
                          final uri = href == null ? null : Uri.tryParse(href);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionIcon(
                        icon: Icons.copy_outlined, tooltip: 'Sao chép', onTap: onCopy),
                    _ActionIcon(
                      icon: post.rating == 'like'
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      tooltip: 'Hữu ích',
                      active: post.rating == 'like',
                      onTap: () => onRate('like'),
                    ),
                    _ActionIcon(
                      icon: post.rating == 'dislike'
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      tooltip: 'Chưa tốt',
                      active: post.rating == 'dislike',
                      onTap: () => onRate('dislike'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.darkTextMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      iconSize: 15,
      tooltip: tooltip,
      color: active ? AppColors.brandPrimary : AppColors.darkTextMuted,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }
}
