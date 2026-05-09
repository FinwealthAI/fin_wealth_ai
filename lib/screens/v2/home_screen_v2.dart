import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../models/dashboard_home.dart';
import '../../models/watchlist_item.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../utils/strategy_icon.dart';
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
  int _openSort = 0; // 0=date, 1=profit

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

  Future<void> _openDailyBlog() async {
    final raw = _dash?.dailyBlogUrl ?? _dash?.dailyBlogPost?.url;
    if (raw == null || raw.isEmpty) return;
    final full = raw.startsWith('http') ? raw : '${ApiConfig.websiteUrl}$raw';
    final uri = Uri.tryParse(full);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
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
      onReadMore: _openDailyBlog,
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
                        if (chartUrl.isNotEmpty)
                          FwMiniButton.soft(
                            label: 'Chart',
                            icon: Icons.show_chart,
                            onTap: () => _openExternal(chartUrl),
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

  Widget _buildOpenPositionsSection() {
    final positions = _dash?.openPositions ?? const [];
    if (_loading || positions.isEmpty) return const SizedBox.shrink();

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
              for (final p in sorted.take(8))
                ListTile(
                  dense: true,
                  leading: Tooltip(
                    message: _buildPositionTooltip(p),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: strategyAccentFromColor(p.presetColor)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        strategyIconFromName(p.presetIcon),
                        size: 16,
                        color: strategyAccentFromColor(p.presetColor),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(p.ticker, style: text.titleSmall),
                      const SizedBox(width: AppSpacing.sm),
                      if (p.unrealizedPct != null)
                        Text(
                          '${p.unrealizedPct! >= 0 ? "+" : ""}${p.unrealizedPct!.toStringAsFixed(2)}%',
                          style: text.labelMedium?.copyWith(
                            color: p.unrealizedPct! >= 0
                                ? AppColors.successDark
                                : AppColors.dangerDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Vào ${p.entryDate}',
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
