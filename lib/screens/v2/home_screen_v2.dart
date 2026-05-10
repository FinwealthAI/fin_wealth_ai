import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../config/api_config.dart';
import '../../models/dashboard_home.dart';
import '../../models/investment_opportunities.dart' show StrategyCardData;
import '../../models/watchlist_item.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../utils/strategy_icon.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import 'notifications_screen_v2.dart';
import 'root_shell_v2.dart' show RootShellNav;
import '../../models/blog_post.dart';
import 'blog_detail_screen_v2.dart';
import 'stock_detail_screen_v2.dart';
import 'stock_search_screen_v2.dart';
import 'strategy_detail_screen_v2.dart';
import 'economic_charts_screen_v2.dart';
import 'upgrade_screen_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  final VoidCallback? onOpenChat;
  const HomeScreenV2({super.key, this.onOpenChat});

  @override
  State<HomeScreenV2> createState() => HomeScreenV2State();
}

class HomeScreenV2State extends State<HomeScreenV2>
    with SingleTickerProviderStateMixin {
  late final InvestmentOpportunitiesRepository _opsRepo =
      context.read<InvestmentOpportunitiesRepository>();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  DashboardHome? _dash;
  Object? _err;
  bool _loading = true;
  int _openSort = 0; // 0=date, 1=profit
  bool _lowPointsWarning = false;

  // Single shimmer controller shared across all skeleton blocks
  late final AnimationController _shimmerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    // Nếu chưa có data, hiện skeleton; nếu đã có (stale-while-revalidate) thì giữ UI cũ
    if (_dash == null) {
      setState(() {
        _loading = true;
        _err = null;
      });
    }
    try {
      final dash = await _opsRepo.fetchDashboardHome(forceRefresh: forceRefresh);
      if (!mounted) return;
      
      // Đồng bộ số điểm vào AuthRepository để hiển thị đúng ở AppBar
      if (_authRepo.accessToken != null) {
        _authRepo.updatePoints(dash.totalPoints, expiration: dash.expirationDate);
        if (mounted) {
          context.read<AuthBloc>().add(AuthUserUpdated({
                'username': _authRepo.username,
                'avatar': _authRepo.avatar,
                'total_points': dash.totalPoints,
                'expiration_date': dash.expirationDate,
              }));
        }
      }

      setState(() {
        _dash = dash;
        _loading = false;
        _err = null;
        _lowPointsWarning = _authRepo.accessToken != null && dash.totalPoints < 30;
      });
    } catch (e) {
      if (!mounted) return;
      // Nếu đã có data cũ, không xoá — chỉ set lỗi nếu chưa có gì
      if (_dash == null) {
        setState(() {
          _err = e;
          _loading = false;
        });
      }
    }
  }

  DailySummaryData? get _summary => _dash?.dailySummary;
  List<WatchlistItem> get _watchlist => _dash?.watchlist ?? const [];

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StockSearchScreenV2()),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreenV2()),
    );
  }

  void _openDetail(String ticker) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => StockDetailScreenV2(ticker: ticker)),
    );
  }

  Future<void> _openDailyBlog() async {
    final blog = _dash?.dailyBlogPost;
    if (blog != null && blog.slug.isNotEmpty) {
      final post = BlogPost(
        id: blog.id,
        title: blog.title,
        slug: blog.slug,
        summary: blog.excerpt,
        thumbnailUrl: blog.coverImage,
        publishedAt: blog.publishedAt,
        viewsCount: blog.viewsCount,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BlogDetailScreenV2(post: post)),
      );
      return;
    }
    // Fallback: open in external browser
    final raw = _dash?.dailyBlogUrl ?? blog?.url;
    if (raw == null || raw.isEmpty) return;
    final full = raw.startsWith('http') ? raw : '${ApiConfig.websiteUrl}$raw';
    final uri = Uri.tryParse(full);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _userName {
    final u = _authRepo.username;
    if (u == null || u.isEmpty) return 'Khách';
    return u;
  }

  List<AiOpportunitySignal> get _signals =>
      _summary?.aiOpportunities ?? const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: HomeAppBar(
        userName: _userName,
        avatarUrl: _authRepo.avatar,
        premiumLabel: _authRepo.accessToken == null
            ? 'Đăng nhập để mở Premium'
            : null,
        daysLeft: _authRepo.accessToken != null ? _authRepo.totalPoints : null,
        expirationDate: _authRepo.expirationDate,
        lowPointsWarning: _lowPointsWarning,
        hasUnreadNotification: false,
        onAvatarTap: () => RootShellNav.goMore(),
        onSearchTap: _openSearch,
        onNotificationTap: _openNotifications,
        onUpgradeTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpgradeScreenV2()),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: _loading
            ? _buildFullPageSkeleton()
            : ListView(
                padding: const EdgeInsets.only(
                    top: AppSpacing.sm, bottom: AppSpacing.xxxl),
                children: [
                  _buildAiInsight(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChainStoriesSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildOpportunitiesSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildOpenPositionsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildReportHighlightsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStrategyCardsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildWatchlistSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildFullPageSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final shimmer = LinearGradient(
          colors: const [
            AppColors.darkSurface,
            AppColors.darkSurfaceElevated,
            AppColors.darkSurface,
          ],
          stops: [0.0, _shimmerCtrl.value, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

        Widget block(double height, {double? width, double radius = AppRadius.lg}) =>
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: shimmer,
                borderRadius: BorderRadius.circular(radius),
              ),
            );

        const h = AppSpacing.lg;
        const px = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Insight card
              Padding(padding: px, child: block(180)),
              const SizedBox(height: h),
              // Section header label
              Padding(padding: px, child: block(14, width: 140, radius: AppRadius.sm)),
              const SizedBox(height: AppSpacing.md),
              // Opportunity cards row
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: px,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, __) => block(120, width: 200),
                ),
              ),
              const SizedBox(height: h),
              // Section header label
              Padding(padding: px, child: block(14, width: 120, radius: AppRadius.sm)),
              const SizedBox(height: AppSpacing.md),
              // List rows
              for (int i = 0; i < 3; i++) ...[
                Padding(padding: px, child: block(68)),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: h),
              // Section header label
              Padding(padding: px, child: block(14, width: 160, radius: AppRadius.sm)),
              const SizedBox(height: AppSpacing.md),
              // Strategy cards row
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: px,
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, __) => block(200, width: 260),
                ),
              ),
              const SizedBox(height: h),
              // Section header label
              Padding(padding: px, child: block(14, width: 100, radius: AppRadius.sm)),
              const SizedBox(height: AppSpacing.md),
              // Watchlist rows
              for (int i = 0; i < 4; i++) ...[
                Padding(padding: px, child: block(60, radius: AppRadius.md)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiInsight() {
    if (_err != null) {
      return _SectionError(
        message:
            'Không tải được dữ liệu: ${_err.toString().replaceFirst('Exception: ', '')}',
        onRetry: _load,
      );
    }
    final s = _summary;
    if (s == null) {
      return _SectionError(
        message: 'Mr.Wealth chưa có nhận định cho hôm nay',
        onRetry: _load,
      );
    }

    final plain = _stripHtml(s.aiGeneratedSummary);
    final firstSentence = _firstSentence(plain);
    final headline = firstSentence.isEmpty
        ? 'Mr.Wealth nhận định thị trường'
        : _truncate(firstSentence, 120);
    final summary =
        plain.isEmpty ? 'Đang cập nhật nhận định thị trường…' : _truncate(plain, 220);
    final sentiment = _moodFromString(s.marketMood);

    return AiInsightCard(
      headline: headline,
      summary: summary,
      vnIndex: s.vnIndex ?? 0,
      vnIndexChangePct: s.vnIndexChange ?? 0,
      sentiment: sentiment,
      publishedAt: s.date,
      onReadMore: _openDailyBlog,
      onAskAI: widget.onOpenChat,
    );
  }

  Widget _buildChainStoriesSection() {
    final stories = _summary?.chainStories ?? const [];
    if (stories.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FwSectionHeader(
          title: 'Biến động chuỗi giá trị',
          icon: Icons.account_tree_outlined,
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: stories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) {
              final raw = stories[i];
              if (raw is! Map) return const SizedBox.shrink();
              final m = Map<String, dynamic>.from(raw);
              final indicator = (m['indicator_name'] ?? '').toString();
              final change = (m['change_str'] ?? '').toString();
              final title = (m['title'] ?? '').toString();
              final narrative = (m['narrative'] ?? '').toString();
              final chartUrl = (m['chart_url'] ?? '').toString();
              final indicatorId = m['indicator_id'] is int
                  ? m['indicator_id'] as int
                  : int.tryParse(m['indicator_id']?.toString() ?? '');
              final color =
                  _colorFromClass(m['color_class']?.toString());
              return Container(
                width: 260,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border:
                      Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FwBadge(
                              label: indicator, tone: FwBadgeTone.info),
                        ),
                        const SizedBox(width: 6),
                        Text(change,
                            style: text.labelSmall
                                ?.copyWith(color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title.isEmpty ? indicator : title,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        narrative,
                        style: text.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FwMiniButton.soft(
                          label: 'Chi tiết',
                          icon: Icons.info_outline,
                          onTap: () => _showChainStoryDetail(m),
                        ),
                        const SizedBox(width: 6),
                        if (indicatorId != null || chartUrl.isNotEmpty)
                          FwMiniButton.soft(
                            label: 'Biểu đồ',
                            icon: Icons.show_chart,
                            onTap: () {
                              if (indicatorId != null) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => EconomicChartsScreenV2(
                                    openIndicatorId: indicatorId,
                                    openIndicatorTitle:
                                        (m['indicator_name'] ?? '').toString(),
                                  ),
                                ));
                              } else {
                                _openExternal(chartUrl);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openExternal(String path) async {
    final full = path.startsWith('http')
        ? path
        : '${ApiConfig.websiteUrl}$path';
    final uri = Uri.tryParse(full);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
  }

  void _showChainStoryDetail(Map<String, dynamic> m) {
    final title = (m['title'] ?? m['indicator_name'] ?? '').toString();
    final indicator = (m['indicator_name'] ?? '').toString();
    final change = (m['change_str'] ?? '').toString();
    final narrative = (m['narrative'] ?? '').toString();
    final fullAnalysis = (m['full_analysis'] ?? '').toString();
    final color = _colorFromClass(m['color_class']?.toString());
    final tickers = m['tickers'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: FwBadge(
                        label: indicator, tone: FwBadgeTone.info),
                  ),
                  const SizedBox(width: 6),
                  Text(change,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: color)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (narrative.isNotEmpty) ...[
                Text(narrative,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
              ],
              if (fullAnalysis.isNotEmpty &&
                  _stripHtml(fullAnalysis).trim() != narrative.trim()) ...[
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text(_stripHtml(fullAnalysis),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
              ],
              Builder(builder: (_) {
                final validTickers = <String>[];
                if (tickers is List) {
                  for (final t in tickers) {
                    String? code;
                    if (t is Map && t['ticker'] != null) {
                      code = t['ticker'].toString();
                    } else if (t is String) {
                      code = t;
                    }
                    if (code == null) continue;
                    final c = code.trim().toUpperCase();
                    if (c.length >= 2 &&
                        c.length <= 6 &&
                        RegExp(r'^[A-Z0-9]+$').hasMatch(c)) {
                      validTickers.add(c);
                    }
                  }
                }
                if (validTickers.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã hưởng lợi',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in validTickers)
                          ActionChip(
                            label: Text(c),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _openDetail(c);
                            },
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHighlightsSection() {
    final reports = _summary?.reportHighlights ?? const [];
    if (reports.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Báo cáo nổi bật',
          icon: Icons.description_outlined,
          actionLabel: 'Tất cả',
          onAction: () {},
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              for (final r in reports.take(4))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.article_outlined,
                      color: AppColors.brandSecondaryDark),
                  title: Text(r.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r.source} · ${r.date}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.darkTextMuted),
                  onTap: () {},
                ),
            ],
          ),
        ),
      ],
    );
  }

  static Color _colorFromClass(String? c) {
    switch (c) {
      case 'emerald':
      case 'green':
        return AppColors.successDark;
      case 'red':
        return AppColors.dangerDark;
      case 'amber':
      case 'yellow':
        return AppColors.warningDark;
      case 'blue':
        return AppColors.brandSecondaryDark;
      default:
        return AppColors.brandPrimaryDark;
    }
  }

  Widget _buildOpportunitiesSection() {
    final signals = _signals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Top cơ hội hôm nay',
          icon: Icons.workspace_premium,
          actionLabel: 'Xem tất cả',
          onAction: () => RootShellNav.goStrategy(),
        ),
        if (signals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Chưa có tín hiệu mở mới hôm nay',
                style: TextStyle(color: AppColors.darkTextMuted)),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: signals.length.clamp(0, 8),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (ctx, i) {
                final sig = signals[i];
                final upside = (sig.takeProfit != null &&
                        sig.entryPrice != null &&
                        sig.entryPrice! > 0)
                    ? ((sig.takeProfit! - sig.entryPrice!) /
                            sig.entryPrice!) *
                        100
                    : 0.0;
                final kind = _kindFromUpside(upside);
                final score =
                    (5 + (upside.abs().clamp(0, 30) / 6)).clamp(0, 10);
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.74,
                  child: OpportunityCard(
                    ticker: sig.ticker,
                    kind: kind,
                    score: score.toDouble(),
                    changePct: upside,
                    strategyName: sig.presetName,
                    strategyIcon: strategyIconFromName(sig.presetIcon),
                    strategyAccent: strategyAccentFromColor(sig.presetColor),
                    faTier: sig.faTier,
                    taTier: sig.taTier,
                    stopLoss: sig.stopLoss,
                    takeProfit: sig.takeProfit,
                    winRate: sig.winRate,
                    profitFactor: sig.profitFactor,
                    maxDrawdown: sig.maxDrawdown,
                    onTap: () => _openDetail(sig.ticker),
                    onDetail: () => _openDetail(sig.ticker),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStrategyCardsSection() {
    final allCards = _summary?.strategyCards ?? const [];
    final unfollowed =
        allCards.where((c) => !c.isFollowing && !c.isOwned).toList();
    final cards = unfollowed.isNotEmpty ? unfollowed : allCards;
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Chiến lược nổi bật',
          icon: Icons.insights,
          actionLabel: 'Xem tất cả',
          onAction: () => RootShellNav.goStrategy(),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: cards.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) => _StrategyCard(card: cards[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistSection() {
    if (_authRepo.accessToken == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FwSectionHeader(
            title: 'Theo dõi',
            icon: Icons.favorite_border,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwEmptyState(
              icon: Icons.lock_outline,
              title: 'Đăng nhập để theo dõi cổ phiếu',
              action: FwButton(
                label: 'Đăng nhập',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/login-v2'),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Theo dõi',
          icon: Icons.favorite_border,
          actionLabel: 'Quản lý',
          onAction: () {},
        ),
        if (_watchlist.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Danh sách theo dõi của bạn đang trống',
                style: TextStyle(color: AppColors.darkTextMuted)),
          )
        else
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                for (final w in _watchlist.take(6))
                  WatchlistRow(
                    ticker: w.ticker,
                    price: w.currentPrice ?? 0,
                    changePct: w.changePercent ?? 0,
                    faTier: w.faTier,
                    taTier: w.taTier,
                    onTap: () => _openDetail(w.ticker),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOpenPositionsSection() {
    final positions = _dash?.openPositions ?? const [];
    if (positions.isEmpty) return const SizedBox.shrink();

    final sorted = [...positions];
    if (_openSort == 0) {
      sorted.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    } else {
      sorted.sort((a, b) =>
          (b.unrealizedPct ?? -999).compareTo(a.unrealizedPct ?? -999));
    }

    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Vị thế đang mở',
          icon: Icons.flag_outlined,
          actionLabel: '${_dash?.openCount ?? 0} mở',
          onAction: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Theo ngày'),
                selected: _openSort == 0,
                onSelected: (_) => setState(() => _openSort = 0),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: const Text('Theo lợi nhuận'),
                selected: _openSort == 1,
                onSelected: (_) => setState(() => _openSort = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < sorted.take(8).length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: AppColors.darkBorder.withValues(alpha: 0.5)),
                _buildPositionRow(sorted[i], text),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static OpportunityKind _kindFromUpside(double y) {
    if (y > 15) return OpportunityKind.golden;
    if (y > 5) return OpportunityKind.value;
    if (y >= 0) return OpportunityKind.wave;
    return OpportunityKind.waiting;
  }

  static MarketSentiment _moodFromString(String? mood) {
    if (mood == null) return MarketSentiment.neutral;
    final m = mood.toLowerCase();
    if (m.contains('tích')) return MarketSentiment.bullish;
    if (m.contains('tiêu')) return MarketSentiment.bearish;
    return MarketSentiment.neutral;
  }

  static String _stripHtml(String s) {
    return s
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildPositionRow(OpenPosition p, TextTheme text) {
    final accent = strategyAccentFromColor(p.presetColor);
    final pct = p.unrealizedPct;
    final pctColor = pct == null
        ? AppColors.darkTextMuted
        : (pct >= 0 ? AppColors.successDark : AppColors.dangerDark);
    final pctLabel = pct == null
        ? '—'
        : '${pct >= 0 ? "+" : ""}${pct.toStringAsFixed(2)}%';

    return InkWell(
      onTap: () => _openDetail(p.ticker),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            // Icon
            Tooltip(
              message: _buildPositionTooltip(p),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(strategyIconFromName(p.presetIcon),
                    size: 16, color: accent),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Left: ticker + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.ticker,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Vào ${p.entryDate}',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            ),

            // Right: pct + entry price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pctLabel,
                    style: text.labelMedium?.copyWith(
                        color: pctColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (p.entryPrice != null)
                  Text(
                    'Giá vào: ${p.entryPrice!.toStringAsFixed(0)}',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.darkTextMuted),
                  )
                else if (p.presetName != null)
                  Text(
                    p.presetName!,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.darkTextMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right,
                color: AppColors.darkTextMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _buildPositionTooltip(OpenPosition p) {
    final sb = StringBuffer();
    sb.writeln('Chiến lược: ${p.presetName ?? "FinWealth"}');
    if (p.stopLoss != null) {
      sb.writeln('Cắt lỗ: ${p.stopLoss!.toStringAsFixed(0)}');
    }
    if (p.takeProfit != null) {
      sb.writeln('Chốt lời: ${p.takeProfit!.toStringAsFixed(0)}');
    }
    if (p.winRate != null) {
      sb.writeln('Tỉ lệ thắng: ${(p.winRate! * 100).toStringAsFixed(1)}%');
    }
    if (p.profitFactor != null) {
      sb.writeln('Profit Factor: ${p.profitFactor!.toStringAsFixed(2)}');
    }
    if (p.maxDrawdown != null) {
      sb.writeln('Sụt giảm tối đa: ${(p.maxDrawdown! * 100).toStringAsFixed(1)}%');
    }
    return sb.toString().trim();
  }

  static String _firstSentence(String s) {
    final m = RegExp(r'[\.!?]').firstMatch(s);
    if (m == null) return s;
    return s.substring(0, m.start).trim();
  }

  static String _truncate(String s, int n) {
    if (s.length <= n) return s;
    return '${s.substring(0, n)}…';
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off,
                color: AppColors.darkTextMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: AppColors.darkTextSecondary)),
            ),
            FwMiniButton.soft(
              label: 'Thử lại',
              icon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyCard extends StatefulWidget {
  final StrategyCardData card;
  const _StrategyCard({required this.card});

  @override
  State<_StrategyCard> createState() => _StrategyCardState();
}

class _StrategyCardState extends State<_StrategyCard> {
  late bool _isFollowing = widget.card.isFollowing;
  bool _followLoading = false;

  bool get _isAi =>
      (widget.card.ownerUsername ?? '').toUpperCase() == 'AI';
  bool get _isTechnical =>
      (widget.card.filterType ?? '').toUpperCase() == 'TECHNICAL';
  IconData get _icon =>
      _isTechnical ? Icons.memory : Icons.diamond_outlined;
  Color get _iconColor => _isTechnical
      ? AppColors.brandSecondaryDark
      : const Color(0xFF9B59B6);

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthRepository>();
    if (auth.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để theo dõi chiến lược')),
      );
      return;
    }
    setState(() => _followLoading = true);
    final repo = context.read<InvestmentOpportunitiesRepository>();
    final ok = _isFollowing
        ? await repo.unfollowStrategy(widget.card.presetId)
        : await repo.followStrategy(widget.card.presetId);
    if (!mounted) return;
    if (ok) setState(() => _isFollowing = !_isFollowing);
    setState(() => _followLoading = false);
  }

  void _openDetail() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StrategyDetailScreenV2(card: widget.card),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final perf = card.perfYear;
    final showPerf = card.showPerformance && perf != null;
    final perfPositive = (perf ?? 0) >= 0;
    final perfColor =
        perfPositive ? AppColors.successDark : AppColors.dangerDark;
    final desc = (card.description ?? '').trim();
    final hasRisk = (card.riskLevel ?? '').isNotEmpty;
    final hasPeriod = (card.investPeriod ?? '').isNotEmpty;

    return Container(
      width: 264,
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, size: 15, color: _iconColor),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dangerDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${card.tickerCount} mã',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dangerDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (_isAi)
                const _Badge(
                  label: 'AI Advisor',
                  color: Color(0xFF9B59B6),
                  filled: true,
                ),
              _Badge(
                icon: _isTechnical ? Icons.memory : Icons.bar_chart,
                label: _isTechnical ? 'Định lượng' : 'Cơ bản',
                color: _isTechnical
                    ? AppColors.brandSecondaryDark
                    : AppColors.successDark,
              ),
              if (card.hasAutoExit)
                const _Badge(
                  icon: Icons.shield_outlined,
                  label: 'Auto exit',
                  color: AppColors.successDark,
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.darkTextSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (hasRisk || hasPeriod) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (hasRisk)
                  _Badge(
                    icon: Icons.speed,
                    label: StrategyCardData.riskLabel(card.riskLevel),
                    color: AppColors.warningDark,
                  ),
                if (hasPeriod)
                  _Badge(
                    icon: Icons.schedule,
                    label: StrategyCardData.periodLabel(card.investPeriod),
                    color: AppColors.brandSecondaryDark,
                  ),
              ],
            ),
          ],
          const Spacer(),
          if (showPerf) ...[
            Row(
              children: [
                Icon(
                  perfPositive
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  size: 18,
                  color: perfColor,
                ),
                Text(
                  '1Y ${perfPositive ? '+' : ''}${perf.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: perfColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              GestureDetector(
                onTap: _openDetail,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimaryDark,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward,
                        size: 11, color: AppColors.brandPrimaryDark),
                  ],
                ),
              ),
              const Spacer(),
              if (!card.isOwned)
                _followLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _FollowButton(
                        isFollowing: _isFollowing,
                        onTap: _toggleFollow,
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool filled;
  const _Badge({
    this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : color.withValues(alpha: 0.12);
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onTap;
  const _FollowButton({required this.isFollowing, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isFollowing) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.successDark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: AppColors.successDark.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 11, color: AppColors.successDark),
              SizedBox(width: 4),
              Text(
                'Đang theo dõi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.successDark,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryDark,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 11, color: Colors.white),
            SizedBox(width: 3),
            Text(
              'Theo dõi',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

