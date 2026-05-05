import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/dashboard_home.dart';
import '../../models/watchlist_item.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import 'notifications_screen_v2.dart';
import 'root_shell_v2.dart' show RootShellNav;
import 'stock_detail_screen_v2.dart';
import 'stock_search_screen_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  final VoidCallback? onOpenChat;
  const HomeScreenV2({super.key, this.onOpenChat});

  @override
  State<HomeScreenV2> createState() => HomeScreenV2State();
}

class HomeScreenV2State extends State<HomeScreenV2> {
  late final InvestmentOpportunitiesRepository _opsRepo =
      context.read<InvestmentOpportunitiesRepository>();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  DashboardHome? _dash;
  Object? _err;
  bool _loading = true;

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
      final dash = await _opsRepo.fetchDashboardHome();
      if (!mounted) return;
      setState(() {
        _dash = dash;
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
      appBar: HomeAppBar(
        userName: _userName,
        premiumLabel: _authRepo.accessToken == null
            ? 'Đăng nhập để mở Premium'
            : null,
        hasUnreadNotification: false,
        onAvatarTap: () {},
        onSearchTap: _openSearch,
        onNotificationTap: _openNotifications,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(
              top: AppSpacing.sm, bottom: AppSpacing.xxxl),
          children: [
            _buildAiInsight(),
            const SizedBox(height: AppSpacing.lg),
            _buildAiTopPick(),
            const SizedBox(height: AppSpacing.lg),
            _buildWealthScoreSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildChainStoriesSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildOpportunitiesSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildOpenPositionsSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSignalsSection(),
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

  Widget _buildAiInsight() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: FwSkeleton(height: 180, radius: AppRadius.lg),
      );
    }
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
      onReadMore: () {},
      onAskAI: widget.onOpenChat,
    );
  }

  Widget _buildChainStoriesSection() {
    final stories = _summary?.chainStories ?? const [];
    if (_loading || stories.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FwSectionHeader(
          title: 'Biến động chuỗi giá trị',
          icon: Icons.account_tree_outlined,
        ),
        SizedBox(
          height: 130,
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
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportHighlightsSection() {
    final reports = _summary?.reportHighlights ?? const [];
    if (_loading || reports.isEmpty) return const SizedBox.shrink();
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
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwSkeleton(height: 180, radius: AppRadius.lg),
          )
        else if (signals.isEmpty)
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
                    faStrength: sig.presetName.length > 14
                        ? '${sig.presetName.substring(0, 14)}…'
                        : sig.presetName,
                    taStrength: sig.signalDate ?? '',
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

  Widget _buildSignalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Tín hiệu hôm nay',
          icon: Icons.bolt,
          actionLabel: 'Xem tất cả',
          onAction: () => RootShellNav.goStrategy(),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwSkeleton(height: 120, radius: AppRadius.lg),
          )
        else if (_signals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Chưa có tín hiệu hôm nay',
                style: TextStyle(color: AppColors.darkTextMuted)),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                for (final s in _signals.take(6))
                  SignalRow(
                    date: s.signalDate ?? '',
                    ticker: s.ticker,
                    kind: SignalKind.buy,
                    strategy: s.presetName,
                    onTap: () => _openDetail(s.ticker),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStrategyCardsSection() {
    final cards = _summary?.strategyCards ?? const [];
    if (_loading || cards.isEmpty) return const SizedBox.shrink();
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
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: cards.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) {
              final c = cards[i];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(AppSpacing.md),
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
                        const Icon(Icons.bolt,
                            size: 14, color: AppColors.brandPrimaryDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.tickerCount} cổ phiếu · ${c.followerCount} theo dõi',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (c.author != null && c.author!.isNotEmpty)
                      Text(
                        c.author!,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildWatchlistSection() {
    if (_authRepo.accessToken == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FwSectionHeader(
            title: 'Watchlist',
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
          title: 'Watchlist',
          icon: Icons.favorite_border,
          actionLabel: 'Quản lý',
          onAction: () {},
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwSkeleton(height: 120, radius: AppRadius.lg),
          )
        else if (_watchlist.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Watchlist của bạn đang trống',
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
                    onTap: () => _openDetail(w.ticker),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAiTopPick() {
    final pick = _dash?.aiTopPick;
    if (_loading || pick == null || pick.isEmpty) return const SizedBox.shrink();
    final ticker = (pick['ticker'] ?? '').toString();
    if (ticker.isEmpty) return const SizedBox.shrink();
    final reason = (pick['reason'] ?? pick['summary'] ?? '').toString();
    final upside = pick['upside_pct'] is num ? (pick['upside_pct'] as num).toDouble() : null;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => _openDetail(ticker),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Top Pick · $ticker',
                        style: text.titleSmall?.copyWith(color: Colors.white)),
                    if (reason.isNotEmpty)
                      Text(_truncate(_stripHtml(reason), 110),
                          style: text.bodySmall?.copyWith(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (upside != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('+${upside.toStringAsFixed(1)}%',
                      style: text.labelSmall?.copyWith(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWealthScoreSection() {
    final dash = _dash;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: FwSkeleton(height: 200, radius: AppRadius.lg),
      );
    }
    if (dash == null) return const SizedBox.shrink();

    final groups = <_WsGroup>[
      _WsGroup('Cơ hội vàng', Icons.workspace_premium, AppColors.warningDark,
          dash.wsGolden, dash.wsGoldenCount),
      _WsGroup('Giá trị đang nổi', Icons.trending_up, AppColors.successDark,
          dash.wsRising, dash.wsRisingCount),
      _WsGroup('Sóng đang nổi', Icons.waves, AppColors.brandSecondaryDark,
          dash.wsWave, dash.wsWaveCount),
      _WsGroup('Giá trị chờ thời', Icons.hourglass_bottom,
          AppColors.brandPrimaryDark, dash.wsValue, dash.wsValueCount),
    ];
    final visible = groups.where((g) => g.items.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FwSectionHeader(
          title: 'Top WealthScore',
          icon: Icons.diamond_outlined,
        ),
        for (final g in visible) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(g.icon, color: g.color, size: 16),
                const SizedBox(width: 6),
                Text(g.label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: g.color)),
                const SizedBox(width: 6),
                Text('(${g.totalCount})',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
              itemCount: g.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (ctx, i) => _wsCard(g.items[i], g.color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _wsCard(WealthScoreItem w, Color accent) {
    final text = Theme.of(context).textTheme;
    final chg = w.changePct ?? 0;
    final chgColor = chg >= 0 ? AppColors.successDark : AppColors.dangerDark;
    return GestureDetector(
      onTap: () => _openDetail(w.ticker),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(w.ticker, style: text.titleSmall),
                const Spacer(),
                Text('${w.score.toStringAsFixed(0)}',
                    style: text.labelLarge?.copyWith(color: accent)),
              ],
            ),
            if (w.close != null)
              Text(
                '${w.close!.toStringAsFixed(0)}đ  '
                '${chg >= 0 ? "+" : ""}${chg.toStringAsFixed(1)}%',
                style: text.labelSmall?.copyWith(color: chgColor),
              ),
            if (w.matchedPresetNames.isNotEmpty)
              Text(
                w.matchedPresetNames.first,
                style: text.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenPositionsSection() {
    final positions = _dash?.openPositions ?? const [];
    if (_loading || positions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwSectionHeader(
          title: 'Vị thế đang mở',
          icon: Icons.flag_outlined,
          actionLabel: '${_dash?.openCount ?? 0} mở',
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
              for (final p in positions.take(6))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.trending_up,
                      color: AppColors.successDark),
                  title: Text(p.ticker),
                  subtitle: Text(
                    '${p.presetName ?? "—"} · vào ${p.entryDate}'
                    '${p.entryPrice != null ? " @ ${p.entryPrice!.toStringAsFixed(0)}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.darkTextMuted),
                  onTap: () => _openDetail(p.ticker),
                ),
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

class _WsGroup {
  final String label;
  final IconData icon;
  final Color color;
  final List<WealthScoreItem> items;
  final int totalCount;
  _WsGroup(this.label, this.icon, this.color, this.items, this.totalCount);
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
