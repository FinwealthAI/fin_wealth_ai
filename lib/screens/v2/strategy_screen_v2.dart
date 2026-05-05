import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/investment_opportunities.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/opportunity_card.dart';
import '../../widgets/strategy/community_strategy_card.dart';
import '../../widgets/strategy/following_strategy_card.dart';
import 'stock_detail_screen_v2.dart';

class StrategyScreenV2 extends StatefulWidget {
  final int initialTab;
  const StrategyScreenV2({super.key, this.initialTab = 0});

  @override
  State<StrategyScreenV2> createState() => _StrategyScreenV2State();
}

class _StrategyScreenV2State extends State<StrategyScreenV2> {
  late int _tab = widget.initialTab;
  int _opFilter = 0;

  late final InvestmentOpportunitiesRepository _opsRepo =
      context.read<InvestmentOpportunitiesRepository>();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  // Top Wealth — opportunities derived from bubble.points
  List<BubblePoint> _bubble = const [];
  bool _loadingBubble = true;
  Object? _bubbleErr;

  // Community / Following — strategies from marketplace
  List<StrategyCardData> _community = const [];
  List<StrategyCardData> _following = const [];
  bool _loadingCommunity = true;
  bool _loadingFollowing = true;
  Object? _communityErr, _followingErr;

  final _tabs = const ['Top Wealth', 'Đang theo dõi', 'Cộng đồng'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBubble(),
      _loadCommunity(),
      if (_authRepo.accessToken != null) _loadFollowing(),
    ]);
  }

  Future<void> _loadBubble() async {
    setState(() {
      _loadingBubble = true;
      _bubbleErr = null;
    });
    try {
      final ops = await _opsRepo.fetch();
      if (!mounted) return;
      setState(() {
        _bubble = ops?.bubble ?? const [];
        _loadingBubble = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bubbleErr = e;
        _loadingBubble = false;
      });
    }
  }

  Future<void> _loadCommunity() async {
    setState(() {
      _loadingCommunity = true;
      _communityErr = null;
    });
    try {
      final list = await _opsRepo.fetchStrategies(tab: 'community');
      if (!mounted) return;
      setState(() {
        _community = list;
        _loadingCommunity = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _communityErr = e;
        _loadingCommunity = false;
      });
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _loadingFollowing = true;
      _followingErr = null;
    });
    try {
      final list = await _opsRepo.fetchStrategies(tab: 'following');
      if (!mounted) return;
      setState(() {
        _following = list;
        _loadingFollowing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followingErr = e;
        _loadingFollowing = false;
      });
    }
  }

  void _openDetail(String ticker) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => StockDetailScreenV2(ticker: ticker)),
    );
  }

  static OpportunityKind _kindFromGap(double y) {
    if (y > 15) return OpportunityKind.golden;
    if (y > 5) return OpportunityKind.value;
    if (y >= 0) return OpportunityKind.wave;
    return OpportunityKind.waiting;
  }

  @override
  Widget build(BuildContext context) {
    final sortedBubble = _bubble.toList()
      ..sort((a, b) => b.y.abs().compareTo(a.y.abs()));

    return Scaffold(
      appBar: const FwAppBar(
        title: 'Chiến lược',
        subtitle: 'Khám phá cơ hội đầu tư',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: FwSegmentedTabs(
              tabs: _tabs,
              active: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          if (_tab == 0 && sortedBubble.isNotEmpty)
            OpportunityFilterBar(
              activeIndex: _opFilter,
              onChanged: (i) => setState(() => _opFilter = i),
              items: [
                (kind: null, count: sortedBubble.length),
                (
                  kind: OpportunityKind.golden,
                  count: sortedBubble.where((e) => e.y > 15).length
                ),
                (
                  kind: OpportunityKind.value,
                  count:
                      sortedBubble.where((e) => e.y > 5 && e.y <= 15).length
                ),
                (
                  kind: OpportunityKind.wave,
                  count:
                      sortedBubble.where((e) => e.y >= 0 && e.y <= 5).length
                ),
                (
                  kind: OpportunityKind.waiting,
                  count: sortedBubble.where((e) => e.y < 0).length
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: switch (_tab) {
              0 => _buildTopWealth(sortedBubble),
              1 => _buildFollowing(),
              _ => _buildCommunity(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopWealth(List<BubblePoint> sorted) {
    if (_loadingBubble) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 120, radius: AppRadius.lg),
      );
    }
    if (_bubbleErr != null && sorted.isEmpty) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được cơ hội',
          action: FwButton(label: 'Thử lại', onPressed: _loadBubble),
        ),
      );
    }

    final selectedKind = const [
      null,
      OpportunityKind.golden,
      OpportunityKind.value,
      OpportunityKind.wave,
      OpportunityKind.waiting,
    ][_opFilter];

    final list = selectedKind == null
        ? sorted
        : sorted.where((p) => _kindFromGap(p.y) == selectedKind).toList();

    if (list.isEmpty) {
      return const Center(
        child: FwEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Không có cơ hội phù hợp',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBubble,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (ctx, i) {
          final p = list[i];
          final kind = _kindFromGap(p.y);
          final score = (5 + (p.y.abs().clamp(0, 30) / 6)).clamp(0, 10);
          return OpportunityCard(
            ticker: p.label,
            kind: kind,
            score: score.toDouble(),
            changePct: p.y,
            faStrength: '—',
            taStrength: '—',
            onTap: () => _openDetail(p.label),
            onDetail: () => _openDetail(p.label),
          );
        },
      ),
    );
  }

  Widget _buildFollowing() {
    if (_authRepo.accessToken == null) {
      return Center(
        child: FwEmptyState(
          icon: Icons.lock_outline,
          title: 'Đăng nhập để theo dõi chiến lược',
          action: FwButton(
            label: 'Đăng nhập',
            onPressed: () => Navigator.of(context).pushNamed('/login-v2'),
          ),
        ),
      );
    }
    if (_loadingFollowing) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 160, radius: AppRadius.lg),
      );
    }
    if (_followingErr != null && _following.isEmpty) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được danh sách theo dõi',
          action: FwButton(label: 'Thử lại', onPressed: _loadFollowing),
        ),
      );
    }
    if (_following.isEmpty) {
      return const Center(
        child: FwEmptyState(
          icon: Icons.bookmark_border,
          title: 'Bạn chưa theo dõi chiến lược nào',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _following.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (ctx, i) {
          final s = _following[i];
          final tickers = s.data
              .take(10)
              .map((e) {
                if (e is Map && e['ticker'] != null) {
                  return e['ticker'].toString();
                }
                return '';
              })
              .where((e) => e.isNotEmpty)
              .toList();
          return FollowingStrategyCard(
            title: s.title,
            tickers: tickers,
            signalsToday: s.tickerCount,
            lastUpdate: s.subtitle ?? '',
            onTap: () {},
            onToggleFollow: () {},
          );
        },
      ),
    );
  }

  Widget _buildCommunity() {
    if (_loadingCommunity) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) =>
            const FwSkeleton(height: 200, radius: AppRadius.lg),
      );
    }
    if (_communityErr != null && _community.isEmpty) {
      return Center(
        child: FwEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Không tải được chiến lược cộng đồng',
          action: FwButton(label: 'Thử lại', onPressed: _loadCommunity),
        ),
      );
    }
    if (_community.isEmpty) {
      return const Center(
        child: FwEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Chưa có chiến lược cộng đồng',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCommunity,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _community.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (ctx, i) {
          final s = _community[i];
          final badges = <StrategyCategoryTag>[];
          if (s.chartType.isNotEmpty) {
            badges.add(StrategyCategoryTag(
              label: _chartTypeLabel(s.chartType),
              color: AppColors.brandPrimaryDark,
            ));
          }
          final tags = <StrategyCategoryTag>[];
          if (s.riskLevel != null && s.riskLevel!.isNotEmpty) {
            tags.add(StrategyCategoryTag(
              label: 'Rủi ro: ${s.riskLevel!}',
              color: AppColors.warningDark,
            ));
          }
          if (s.investPeriod != null && s.investPeriod!.isNotEmpty) {
            tags.add(StrategyCategoryTag(
              label: s.investPeriod!,
              color: AppColors.brandSecondaryDark,
            ));
          }
          return CommunityStrategyCard(
            title: s.title,
            categoryBadges: badges,
            description: s.description ?? s.subtitle ?? '',
            followers: s.followerCount,
            authorName: s.author ?? 'FinWealth',
            tags: tags,
            performance1Y: 0,
            followed: s.isFollowing,
            onResult: () {},
            onToggleFollow: () {},
            onInfo: () {},
          );
        },
      ),
    );
  }

  static String _chartTypeLabel(String t) {
    return switch (t) {
      'bar' => 'Bảng xếp hạng',
      'line' => 'Diễn biến',
      'card_grid' => 'Thẻ chiến lược',
      _ => t,
    };
  }
}
