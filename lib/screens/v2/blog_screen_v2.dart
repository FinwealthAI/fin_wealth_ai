import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/blog_post.dart';
import '../../respositories/blog_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/blog/blog_card.dart';
import '../../widgets/common/common.dart';
import 'blog_detail_screen_v2.dart';

class BlogScreenV2 extends StatefulWidget {
  const BlogScreenV2({super.key});

  @override
  State<BlogScreenV2> createState() => _BlogScreenV2State();
}

class _BlogScreenV2State extends State<BlogScreenV2> {
  late final BlogRepository _repo = context.read<BlogRepository>();

  List<BlogPost> _posts = const [];
  List<BlogCategory> _categories = const [];
  int _categoryIndex = 0; // 0 = "Tất cả"
  bool _loading = true;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? categorySlug}) async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final result = await _repo.fetchPosts(categorySlug: categorySlug);
      if (!mounted) return;
      setState(() {
        _posts = result.posts;
        if (result.categories.isNotEmpty) {
          _categories = result.categories;
        }
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

  List<String> get _categoryLabels =>
      ['Tất cả', ..._categories.map((c) => c.name)];

  void _onCategoryChanged(int idx) {
    if (idx == _categoryIndex) return;
    setState(() => _categoryIndex = idx);
    final slug = idx == 0 ? null : _categories[idx - 1].slug;
    _load(categorySlug: slug);
  }

  void _open(BlogPost p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BlogDetailScreenV2(post: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(
        title: 'Blog đầu tư',
        subtitle: 'Kiến thức từ chuyên gia',
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(
          categorySlug:
              _categoryIndex == 0 ? null : _categories[_categoryIndex - 1].slug,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            if (_categories.isNotEmpty)
              FwFilterPillBar(
                items: _categoryLabels,
                activeIndex: _categoryIndex.clamp(0, _categoryLabels.length - 1),
                onChanged: _onCategoryChanged,
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
          childAspectRatio: 0.85,
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
    if (_posts.isEmpty) {
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
        childAspectRatio: 0.85,
      ),
      itemCount: _posts.length,
      itemBuilder: (ctx, i) {
        final p = _posts[i];
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
