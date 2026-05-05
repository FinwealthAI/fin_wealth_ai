import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blog_post.dart';
import '../../respositories/blog_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/blog/blog_card.dart';
import '../../widgets/common/common.dart';

class BlogScreenV2 extends StatefulWidget {
  const BlogScreenV2({super.key});

  @override
  State<BlogScreenV2> createState() => _BlogScreenV2State();
}

class _BlogScreenV2State extends State<BlogScreenV2> {
  late final BlogRepository _repo = context.read<BlogRepository>();

  int _category = 0;
  List<BlogPost> _posts = const [];
  bool _loading = true;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final posts = await _repo.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
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

  List<String> get _categories {
    final set = <String>{'Tất cả'};
    for (final p in _posts) {
      final c = (p.categoryName ?? '').trim();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  List<BlogPost> get _visible {
    if (_category == 0) return _posts;
    final cats = _categories;
    if (_category >= cats.length) return _posts;
    final target = cats[_category];
    return _posts.where((p) => (p.categoryName ?? '') == target).toList();
  }

  Future<void> _open(BlogPost p) async {
    final uri = Uri.tryParse(p.detailUrl);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(
        title: 'Blog đầu tư',
        subtitle: 'Kiến thức từ chuyên gia',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            FwFilterPillBar(
              items: _categories,
              activeIndex: _category.clamp(0, _categories.length - 1),
              onChanged: (i) => setState(() => _category = i),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.58,
        ),
        itemCount: 6,
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 240, radius: AppRadius.lg),
      );
    }
    if (_err != null) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được blog',
          message: _err.toString().replaceFirst('Exception: ', ''),
          action: FwButton(label: 'Thử lại', onPressed: _load),
        ),
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return const Center(
        child: FwEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Chưa có bài viết',
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemCount: visible.length,
      itemBuilder: (ctx, i) {
        final p = visible[i];
        return BlogCard(
          title: p.title,
          summary: p.summary ?? '',
          imageUrl: p.thumbnailUrl,
          category: (p.categoryName?.isNotEmpty ?? false)
              ? p.categoryName!
              : 'Bài viết',
          authorName: p.authorName ?? 'FinWealth',
          viewCount: p.viewsCount,
          onTap: () => _open(p),
        );
      },
    );
  }
}
