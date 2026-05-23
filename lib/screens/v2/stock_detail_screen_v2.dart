import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../respositories/auth_repository.dart';
import '../../respositories/search_stock_repository.dart';
import '../../respositories/watchlist_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import 'chat_screen_v2.dart';
import 'stock_search_screen_v2.dart';

class StockDetailScreenV2 extends StatefulWidget {
  final String ticker;
  const StockDetailScreenV2({super.key, required this.ticker});

  @override
  State<StockDetailScreenV2> createState() => _StockDetailScreenV2State();
}

class _StockDetailScreenV2State extends State<StockDetailScreenV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final SearchStockRepository _repo =
      context.read<SearchStockRepository>();
  late final AuthRepository _authRepo = context.read<AuthRepository>();
  late final WatchlistRepository _watchRepo =
      context.read<WatchlistRepository>();

  String _priceRange = '1y';
  String _valuationKind = 'PE';
  double _collapseProgress = 0;
  final ValueNotifier<int> _scrollNotifier = ValueNotifier<int>(0);

  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _valuation;
  Map<String, dynamic>? _ratio;
  Map<String, dynamic>? _growth;
  String _growthPeriod = 'quarter'; // 'quarter' | 'year'
  Map<String, dynamic>? _safety;
  Map<String, dynamic>? _technical;

  Map<String, dynamic>? _valuationHistory;
  Map<String, dynamic>? _insight;

  Map<String, dynamic>? _chain;
  bool _loadingChain = true;
  Object? _errChain;
  int _selectedChartIdx = 0;
  int _chartPeriodDays = 365; // 180 | 365 | 1095 | -1 (all)

  bool _loadingOverview = true,
      _loadingValuation = true,
      _loadingValuationHistory = true,
      _loadingRatio = true,
      _loadingGrowth = true,
      _loadingSafety = true,
      _loadingSignals = true,
      _loadingTechnical = true,
      _loadingInsight = true;
  Object? _errOverview, _errValuation, _errValuationHistory, _errRatio, _errGrowth, _errSafety, _errInsight;

  List<dynamic> _signals = [];

  bool _addingToWatchlist = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    if (_authRepo.accessToken != null) {
      _loadAll();
    } else {
      _loadingOverview = false;
      _loadingValuation = false;
      _loadingValuationHistory = false;
      _loadingRatio = false;
      _loadingGrowth = false;
      _loadingSafety = false;
      _loadingSignals = false;
      _loadingTechnical = false;
      _loadingInsight = false;
      _loadingChain = false;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadOverview(),
      _loadValuation(),
      _loadValuationHistory(),
      _loadRatio(),
      _loadGrowth(),
      _loadSafety(),
      _loadSignals(),
      _loadTechnical(),
      _loadInsight(),
      _loadChain(),
    ]);
  }

  Future<void> _loadTechnical() async {
    setState(() => _loadingTechnical = true);
    try {
      final d = await _repo.getTechnicalAnalysis(widget.ticker);
      if (!mounted) return;
      setState(() {
        _technical = d;
        _loadingTechnical = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTechnical = false);
    }
  }

  Future<void> _loadInsight() async {
    setState(() => _loadingInsight = true);
    try {
      final d = await _repo.getInsight(widget.ticker);
      if (!mounted) return;
      setState(() {
        _insight = d;
        _loadingInsight = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errInsight = e;
        _loadingInsight = false;
      });
    }
  }

  Future<void> _loadChain() async {
    setState(() {
      _loadingChain = true;
      _errChain = null;
    });
    try {
      final d = await _repo.getValueChain(widget.ticker);
      if (!mounted) return;
      setState(() {
        _chain = d;
        _selectedChartIdx = 0;
        _loadingChain = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errChain = e;
        _loadingChain = false;
      });
    }
  }

  Future<void> _loadSignals() async {
    setState(() => _loadingSignals = true);
    try {
      final d = await _repo.getSignals(widget.ticker);
      if (!mounted) return;
      setState(() {
        _signals = d;
        _loadingSignals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSignals = false);
    }
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loadingOverview = true;
      _errOverview = null;
    });
    try {
      final d = await _repo.getOverview(widget.ticker);
      if (!mounted) return;
      setState(() {
        _overview = d;
        _loadingOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errOverview = e;
        _loadingOverview = false;
      });
    }
  }

  Future<void> _loadValuation() async {
    setState(() {
      _loadingValuation = true;
      _errValuation = null;
    });
    try {
      final d = await _repo.getValuation(widget.ticker);
      if (!mounted) return;
      setState(() {
        _valuation = d;
        _loadingValuation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errValuation = e;
        _loadingValuation = false;
      });
    }
  }

  Future<void> _loadValuationHistory() async {
    setState(() {
      _loadingValuationHistory = true;
      _errValuationHistory = null;
    });
    try {
      final d = await _repo.getValuationHistory(widget.ticker);
      if (!mounted) return;
      setState(() {
        _valuationHistory = d;
        _loadingValuationHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errValuationHistory = e;
        _loadingValuationHistory = false;
      });
    }
  }

  Future<void> _loadRatio() async {
    setState(() {
      _loadingRatio = true;
      _errRatio = null;
    });
    try {
      final d = await _repo.getCompanyRatio(widget.ticker, _priceRange);
      if (!mounted) return;
      setState(() {
        _ratio = d;
        _loadingRatio = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errRatio = e;
        _loadingRatio = false;
      });
    }
  }

  Future<void> _loadGrowth([String? period]) async {
    final p = period ?? _growthPeriod;
    setState(() { _loadingGrowth = true; _errGrowth = null; });
    try {
      final d = await _repo.getGrowth(widget.ticker, p);
      if (!mounted) return;
      setState(() { _growth = d; _growthPeriod = p; _loadingGrowth = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errGrowth = e; _loadingGrowth = false; });
    }
  }

  Future<void> _loadSafety() async {
    setState(() {
      _loadingSafety = true;
      _errSafety = null;
    });
    try {
      final d = await _repo.getSafety(widget.ticker, '5y');
      if (!mounted) return;
      setState(() {
        _safety = d;
        _loadingSafety = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errSafety = e;
        _loadingSafety = false;
      });
    }
  }

  Future<void> _addToWatchlist() async {
    if (_authRepo.accessToken == null) {
      _promptLogin();
      return;
    }
    setState(() => _addingToWatchlist = true);
    try {
      await _watchRepo.addToWatchlist(widget.ticker);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${widget.ticker} vào watchlist')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _addingToWatchlist = false);
    }
  }

  void _promptLogin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cần đăng nhập'),
        content: const Text(
            'Đăng nhập để mở chi tiết cổ phiếu, theo dõi và nhận khuyến nghị AI.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/login-v2');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ChatScreenV2(initialTicker: widget.ticker)),
    );
  }

  // ===== Helpers to read API fields safely =====
  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').replaceAll('%', '').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }

  String? get _companyName {
    final n = _overview?['company_name'];
    if (n is String && n.isNotEmpty) return n;
    return null;
  }

  double? get _price => _toD(_overview?['price']);
  double? get _changePct => _toD(_overview?['up_size']);
  String? get _faScore {
    final v = _overview?['fa_score'] ?? _overview?['wealth_fa'];
    if (v == null) return null;
    final d = _toD(v);
    return d?.toStringAsFixed(1);
  }

  String? get _taScore {
    final v = _overview?['ta_score'] ?? _overview?['wealth_ta'];
    if (v == null) return null;
    final d = _toD(v);
    return d?.toStringAsFixed(1);
  }

  String _fmt(double? v, {int dec = 2}) {
    if (v == null) return '—';
    final fmt = NumberFormat('#,##0${dec > 0 ? '.' : ''}${'#' * dec}', 'vi_VN');
    return fmt.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authRepo.accessToken == null;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildHeader(context)],
        body: TabBarView(
          controller: _tab,
          children: [
            isGuest ? _guestTab() : _buildOverview(),
            isGuest ? _guestTab() : _buildValuation(),
            isGuest ? _guestTab() : _buildValueChain(),
            isGuest ? _guestTab() : _buildHealth(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _guestTab() {
    return Center(
      child: FwEmptyState(
        icon: Icons.lock_outline,
        title: 'Đăng nhập để xem chi tiết',
        message: 'Bao gồm biểu đồ giá, định giá và sức khỏe tài chính.',
        action: FwButton(
          label: 'Đăng nhập',
          onPressed: () => Navigator.of(context).pushNamed('/login-v2'),
        ),
      ),
    );
  }

  // ---------- Header ----------
  SliverAppBar _buildHeader(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = _price;
    final change = _changePct;
    final positive = (change ?? 0) >= 0;
    final priceColor =
        positive ? AppColors.successDark : AppColors.dangerDark;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 300,
      backgroundColor: AppColors.darkBg,
      leading: const BackButton(),
      actions: [
        IconButton(
          tooltip: 'Tìm cổ phiếu',
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const StockSearchScreenV2()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: _addingToWatchlist ? null : _addToWatchlist,
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {},
        ),
      ],
      title: AnimatedBuilder(
        animation: _scrollNotifier,
        builder: (_, __) {
          final visible = _collapseProgress > 0.65;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: visible ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.ticker,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkTextPrimary,
                    )),
                if (price != null) ...[
                  const SizedBox(width: 8),
                  Text(_fmt(price),
                      style:
                          text.titleSmall?.copyWith(color: priceColor)),
                ],
                if (change != null) ...[
                  const SizedBox(width: 6),
                  Text(
                      '${positive ? '+' : ''}${_fmt(change)}%',
                      style:
                          text.labelSmall?.copyWith(color: priceColor)),
                ],
              ],
            ),
          );
        },
      ),
      flexibleSpace: LayoutBuilder(
        builder: (ctx, constraints) {
          final settings = ctx.dependOnInheritedWidgetOfExactType<
              FlexibleSpaceBarSettings>();
          final delta =
              (settings?.maxExtent ?? 0) - (settings?.minExtent ?? 0);
          final progress = delta <= 0
              ? 0.0
              : (1 -
                      (((settings?.currentExtent ?? 0) -
                              (settings?.minExtent ?? 0)) /
                          delta))
                  .clamp(0.0, 1.0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if ((_collapseProgress - progress).abs() > 0.01) {
              _collapseProgress = progress;
              _scrollNotifier.value++;
            }
          });
          final contentOpacity = (1 - progress * 1.4).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandPrimary.withValues(alpha: 0.18),
                      AppColors.darkBg,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: contentOpacity < 0.05,
                  child: Opacity(
                    opacity: contentOpacity,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 56, AppSpacing.lg, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(widget.ticker, style: text.displayMedium),
                              if (_faScore != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _ScoreChip(label: 'FA', value: _faScore!),
                              ],
                              if (_taScore != null) ...[
                                const SizedBox(width: 6),
                                _ScoreChip(label: 'TA', value: _taScore!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_companyName ?? 'Cổ phiếu',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                  color: AppColors.darkTextSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmt(price),
                                style: text.headlineLarge
                                    ?.copyWith(color: priceColor),
                              ),
                              if (change != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        priceColor.withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          positive
                                              ? Icons.arrow_drop_up
                                              : Icons.arrow_drop_down,
                                          color: priceColor),
                                      Text(
                                          '${positive ? '+' : ''}${_fmt(change)}%',
                                          style: text.titleSmall?.copyWith(
                                              color: priceColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        },
      ),
      bottom: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.brandPrimaryDark,
        labelColor: AppColors.brandPrimaryDark,
        unselectedLabelColor: AppColors.darkTextMuted,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Định giá'),
          Tab(text: 'Chuỗi GT'),
          Tab(text: 'Sức khỏe'),
        ],
      ),
    );
  }

  // ---------- Tab 1: Tổng quan ----------
  Widget _buildOverview() {
    final ranges = const ['1y', '3m', '6m', '3y', '5y'];
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Biểu đồ giá', style: text.titleMedium),
                    const Spacer(),
                    for (final r in ranges) ...[
                      _RangePill(
                        label: r.toUpperCase(),
                        active: _priceRange == r,
                        onTap: () {
                          setState(() => _priceRange = r);
                          _loadRatio();
                        },
                      ),
                      if (r != ranges.last) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 240, child: _buildPriceChart()),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.darkBorder),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 6,
                  children: [
                    const _LegendDot(
                        color: AppColors.brandPrimaryDark,
                        label: 'Giá đóng cửa'),
                    if (_toD(_overview?['avg_target_price']) != null)
                      _LegendDot(
                          color: Colors.orangeAccent,
                          label: 'Định giá TB${(_overview?['valuation_date']?.toString() ?? '').isNotEmpty ? ' (${_overview?['valuation_date']})' : ''}'),
                    if ((_technical?['data'] as Map?)?['levels']?['nearest_support'] != null)
                      const _LegendDot(
                          color: AppColors.successDark,
                          label: 'Hỗ trợ (HT)'),
                    if ((_technical?['data'] as Map?)?['levels']?['nearest_resistance'] != null)
                      const _LegendDot(
                          color: Colors.redAccent,
                          label: 'Kháng cự (KC)'),
                    if (_signals.isNotEmpty)
                      const _LegendDot(
                          color: AppColors.successDark,
                          label: 'Điểm theo dõi mua ▲'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildOpportunityRiskCard(),
        ],
      ),
    );
  }

  Widget _buildOpportunityRiskCard() {
    if (_loadingOverview) {
      return const FwSkeleton(height: 140, radius: AppRadius.lg);
    }
    if (_errOverview != null && _overview == null) {
      return _SectionError(
          message: 'Không tải được tổng quan', onRetry: _loadOverview);
    }
    final o = _overview;
    if (o == null) return const SizedBox.shrink();

    final faScore = _toD(o['fa_score'] ?? o['wealth_fa']) ?? 0.0;

    double upside = 0.0;
    bool valuationReady = !_loadingValuation && _valuation != null;
    if (valuationReady) {
      final price = _toD(o['price']) ?? 0.0;
      final details = (_valuation!['details'] as List<dynamic>?) ?? [];
      if (details.isNotEmpty && price > 0) {
        final targets = details
            .map((d) => _toD((d as Map)['target_price']))
            .whereType<double>()
            .toList();
        if (targets.isNotEmpty) {
          final avg = targets.reduce((a, b) => a + b) / targets.length;
          upside = (avg / price - 1) * 100;
        }
      }
    }

    double opp = (50 + faScore).clamp(0, 90);
    if (valuationReady && upside < 0) {
      opp -= upside.abs().clamp(0, 25);
    }
    opp = opp.clamp(10, 90);
    final risk = 100 - opp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: _OpportunityRiskCard(
        opportunity: opp,
        risk: risk,
        faScore: faScore,
        upside: valuationReady ? upside : null,
        insight: _insight,
      ),
    );
  }

  // ---------- Tab 2: Định giá ----------
  Widget _buildValuation() {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _loadValuation,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Lịch sử định giá', style: text.titleMedium),
                    const Spacer(),
                    _RangePill(
                      label: 'P/E',
                      active: _valuationKind == 'PE',
                      onTap: () => setState(() => _valuationKind = 'PE'),
                    ),
                    const SizedBox(width: 4),
                    _RangePill(
                      label: 'P/B',
                      active: _valuationKind == 'PB',
                      onTap: () => setState(() => _valuationKind = 'PB'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 180, child: _buildValuationChart()),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                      color: _valuationKind == 'PE'
                          ? AppColors.brandPrimaryDark
                          : AppColors.brandSecondaryDark,
                      label: _valuationKind == 'PE' ? 'P/E' : 'P/B',
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const _LegendDot(
                      color: Colors.redAccent,
                      label: 'Trung bình 1 năm',
                      isDashed: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildBrokerTable(),
        ],
      ),
    );
  }

  Widget _buildBrokerTable() {
    final text = Theme.of(context).textTheme;
    if (_loadingValuation) {
      return const FwSkeleton(height: 200, radius: AppRadius.lg);
    }
    if (_errValuation != null && _valuation == null) {
      return _SectionError(
          message: 'Không tải được định giá', onRetry: _loadValuation);
    }
    final details =
        (_valuation?['details'] as List<dynamic>?) ?? const <dynamic>[];

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed,
                    size: 14, color: AppColors.darkTextSecondary),
                const SizedBox(width: 6),
                Text('Chi tiết định giá từ các CTCK',
                    style: text.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (details.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Chưa có khuyến nghị từ CTCK.',
                  style: text.bodySmall),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: const [
                  Expanded(flex: 4, child: _TableHead('Tổ chức')),
                  Expanded(
                      flex: 3,
                      child: _TableHead('Giá MT', alignRight: true)),
                  Expanded(
                      flex: 3,
                      child: _TableHead('Khuyến nghị', alignRight: true)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.darkBorder),
            for (final raw in details)
              _buildBrokerRow(raw as Map<String, dynamic>, text),
          ],
        ],
      ),
    );
  }

  Widget _buildBrokerRow(Map<String, dynamic> d, TextTheme text) {
    final firm = (d['firm_new'] ?? '').toString();
    final target = (d['target_price'] ?? '').toString();
    final rec = (d['recommendation'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Flexible(
                  child: FwBadge(
                    label: firm,
                    tone: FwBadgeTone.info,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('$target đ',
                textAlign: TextAlign.right, style: text.titleSmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              rec.isEmpty ? '—' : rec,
              textAlign: TextAlign.right,
              style: text.titleSmall?.copyWith(
                color: rec.toLowerCase().contains('mua')
                    ? AppColors.successDark
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab 3: Chuỗi giá trị ----------
  Widget _buildValueChain() {
    if (_loadingChain) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errChain != null && _chain == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadChain,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }

    final text = Theme.of(context).textTheme;
    final found = _chain?['found'] == true;
    final charts = (_chain?['charts'] as List?) ?? [];
    final groups = (_chain?['groups'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadChain,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Charts section ─────────────────────────────────────────────
          if (charts.isNotEmpty) ...[
            FwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bar_chart_rounded,
                        size: 16, color: AppColors.brandPrimaryDark),
                    const SizedBox(width: 6),
                    Text('Biểu đồ & Dữ liệu liên quan',
                        style: text.titleMedium),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  // Horizontal chart selector
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: charts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final ch = charts[i] as Map;
                        final active = i == _selectedChartIdx;
                        final corr = ch['correlation'] as String? ?? 'none';
                        return GestureDetector(
                          onTap: () => setState(() => _selectedChartIdx = i),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 130),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.brandPrimaryDark
                                      .withValues(alpha: 0.15)
                                  : AppColors.darkSurface,
                              border: Border.all(
                                color: active
                                    ? AppColors.brandPrimaryDark
                                    : AppColors.darkBorder,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (corr != 'none') ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: corr == 'positive'
                                          ? AppColors.successDark
                                          : AppColors.dangerDark,
                                    ),
                                  ),
                                ],
                                Flexible(
                                  child: Text(
                                    ch['title'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? AppColors.brandPrimaryDark
                                          : AppColors.darkTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Time period filter
                  Row(
                    children: [
                      for (final (label, days) in [
                        ('6T', 180),
                        ('1N', 365),
                        ('3N', 1095),
                        ('Tất cả', -1),
                      ])
                        _ChartPeriodBtn(
                          label: label,
                          active: _chartPeriodDays == days,
                          onTap: () =>
                              setState(() => _chartPeriodDays = days),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Chart
                  _buildEcoChart(charts[_selectedChartIdx] as Map),
                  // Breadcrumb + latest date
                  const SizedBox(height: 6),
                  _buildChartMeta(charts[_selectedChartIdx] as Map),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Value chain groups ─────────────────────────────────────────
          if (found && groups.isNotEmpty)
            FwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.account_tree_outlined,
                        size: 16, color: AppColors.brandPrimaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chuỗi giá trị: ${widget.ticker}',
                        style: text.titleMedium,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  // Timeline with vertical connector
                  Stack(
                    children: [
                      // Vertical line
                      Positioned(
                        left: 19,
                        top: 24,
                        bottom: 24,
                        child: Container(
                          width: 1,
                          color: AppColors.darkBorder,
                        ),
                      ),
                      Column(
                        children: [
                          for (int i = 0; i < groups.length; i++) ...[
                            _buildVcGroup(groups[i] as Map, i),
                            if (i < groups.length - 1)
                              const SizedBox(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (!found)
            FwCard(
              child: Column(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 36, color: AppColors.darkTextMuted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Chưa có sơ đồ chuỗi giá trị cho ${widget.ticker}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.darkTextMuted, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const List<_VcStyle> _vcStyles = [
    _VcStyle(
      iconData: Icons.layers_outlined,
      iconColor: Color(0xFF60A5FA),  // blue-400
      bgColor: Color(0x1A3B82F6),
      borderColor: Color(0x333B82F6),
      pillBg: Color(0x263B82F6),
      pillText: Color(0xFF93C5FD),
    ),
    _VcStyle(
      iconData: Icons.bolt_outlined,
      iconColor: Color(0xFFA78BFA),  // purple-400
      bgColor: Color(0x1A8B5CF6),
      borderColor: Color(0x338B5CF6),
      pillBg: Color(0x268B5CF6),
      pillText: Color(0xFFC4B5FD),
    ),
    _VcStyle(
      iconData: Icons.trending_up,
      iconColor: Color(0xFF34D399),  // emerald-400
      bgColor: Color(0x1A10B981),
      borderColor: Color(0x3310B981),
      pillBg: Color(0x2610B981),
      pillText: Color(0xFF6EE7B7),
    ),
  ];

  Widget _buildVcGroup(Map group, int idx) {
    final style = _vcStyles[idx.clamp(0, 2)];
    final title = group['title'] as String? ?? '';
    final note = group['note'] as String? ?? '';
    final keyCount = group['key_count'] as int? ?? 0;
    final keys = (group['keys'] as List?) ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.bgColor,
            border: Border.all(color: style.borderColor),
          ),
          child: Icon(style.iconData, size: 18, color: style.iconColor),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: style.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary)),
                  ),
                  Text('$keyCount yếu tố',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.darkTextMuted)),
                ]),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                ],
                if (keys.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final k in keys)
                        _buildKeyPills(k as Map, style),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPills(Map key, _VcStyle style) {
    final rootTitle = key['title'] as String? ?? '';
    final children = (key['children'] as List?) ?? [];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Root pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: style.pillBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.borderColor),
          ),
          child: Text(rootTitle,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: style.pillText)),
        ),
        // Arrow + child pills
        if (children.isNotEmpty) ...[
          Text('›',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.darkTextMuted.withValues(alpha: 0.5))),
          for (final c in children)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: style.pillBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: style.borderColor),
              ),
              child: Text((c as Map)['title'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: style.pillText.withValues(alpha: 0.8))),
            ),
        ],
      ],
    );
  }

  Widget _buildChartMeta(Map ch) {
    final breadcrumb = ch['breadcrumb'] as String? ?? '';
    final latestDate = ch['latest_date'] as String? ?? '';
    final corr = ch['correlation'] as String? ?? 'none';

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (breadcrumb.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_open_outlined,
                size: 11, color: AppColors.darkTextMuted),
            const SizedBox(width: 3),
            Text(breadcrumb,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
        if (latestDate.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time,
                size: 11, color: AppColors.darkTextMuted),
            const SizedBox(width: 3),
            Text('Cập nhật: $latestDate',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
        if (corr == 'positive')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Thuận chiều',
                style: TextStyle(fontSize: 9, color: AppColors.successDark)),
          )
        else if (corr == 'negative')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dangerDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Nghịch chiều',
                style: TextStyle(fontSize: 9, color: AppColors.dangerDark)),
          ),
      ],
    );
  }

  Widget _buildEcoChart(Map ch) {
    final data = (ch['data'] as Map?) ?? {};
    final labels = (data['labels'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [];
    final datasets = (data['datasets'] as List?) ?? [];
    if (datasets.isEmpty || labels.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Không có dữ liệu biểu đồ',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
        ),
      );
    }

    final ds0 = datasets[0] as Map;
    final ds1 = datasets.length > 1 ? datasets[1] as Map : null;
    final vals0 = (ds0['values'] as List?) ?? [];
    final vals1 = ds1 != null ? (ds1['values'] as List?) ?? [] : <dynamic>[];

    // Filter by period
    final cutoff = _chartPeriodDays < 0
        ? null
        : DateTime.now().subtract(Duration(days: _chartPeriodDays));

    final filteredLabels = <String>[];
    final filtered0 = <double>[];
    final filtered1 = <double?>[];

    for (int i = 0; i < labels.length; i++) {
      if (i >= vals0.length) break;
      final dt = DateTime.tryParse(labels[i]);
      if (dt == null) continue;
      if (cutoff != null && dt.isBefore(cutoff)) continue;
      final v0 = vals0[i];
      if (v0 == null) continue;
      filteredLabels.add(labels[i]);
      filtered0.add((v0 as num).toDouble());
      if (i < vals1.length && vals1[i] != null) {
        filtered1.add((vals1[i] as num).toDouble());
      } else {
        filtered1.add(null);
      }
    }

    if (filtered0.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Không có dữ liệu trong khoảng thời gian này',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
        ),
      );
    }

    final n = filtered0.length;
    final spots0 = [for (int i = 0; i < n; i++) FlSpot(i.toDouble(), filtered0[i])];
    final hasStock = filtered1.any((v) => v != null);
    final spots1 = hasStock
        ? [
            for (int i = 0; i < n; i++)
              if (filtered1[i] != null) FlSpot(i.toDouble(), filtered1[i]!)
          ]
        : <FlSpot>[];

    // Y ranges
    final min0 = filtered0.reduce((a, b) => a < b ? a : b);
    final max0 = filtered0.reduce((a, b) => a > b ? a : b);
    final pad0 = (max0 - min0).abs() * 0.15 + 0.001;

    final min1 = hasStock
        ? filtered1.whereType<double>().reduce((a, b) => a < b ? a : b)
        : 0.0;
    final max1 = hasStock
        ? filtered1.whereType<double>().reduce((a, b) => a > b ? a : b)
        : 1.0;
    final pad1 = (max1 - min1).abs() * 0.15 + 0.001;

    // X label helper — pick ~5 evenly spaced
    String xLabel(String iso) {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString().substring(2);
      return '$m/$y';
    }

    const double leftReserved = 46;
    const double rightReserved = 46;
    const double bottomReserved = 22;

    // Primary indicator line chart
    final primary = LineChartData(
      minX: 0,
      maxX: (n - 1).toDouble(),
      minY: min0 - pad0,
      maxY: max0 + pad0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.darkBorder, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: leftReserved,
            getTitlesWidget: (v, meta) {
              if (v == meta.max || v == meta.min) {
                return const SizedBox.shrink();
              }
              final s = v.abs() >= 10000
                  ? '${(v / 1000).toStringAsFixed(0)}k'
                  : v.abs() >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : v.toStringAsFixed(1);
              return Text(s,
                  style: const TextStyle(
                      color: AppColors.darkTextMuted, fontSize: 9));
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: hasStock ? rightReserved : 8,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReserved,
            getTitlesWidget: (v, _) {
              final i = v.round();
              if (i < 0 || i >= filteredLabels.length) {
                return const SizedBox.shrink();
              }
              // Show ~5 labels
              final step = (n / 5).ceil().clamp(1, n);
              if (i % step != 0 && i != n - 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(xLabel(filteredLabels[i]),
                    style: const TextStyle(
                        color: AppColors.darkTextMuted, fontSize: 9)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots0,
          isCurved: true,
          color: AppColors.brandPrimaryDark,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.brandPrimaryDark.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.darkSurface,
          getTooltipItems: (spots) => spots.map((s) {
            final i = s.x.round().clamp(0, filteredLabels.length - 1);
            return LineTooltipItem(
              '${xLabel(filteredLabels[i])}\n${s.y.toStringAsFixed(2)}',
              const TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
    );

    // Stock price overlay (right axis)
    LineChartData? stockOverlay;
    if (hasStock && spots1.isNotEmpty) {
      stockOverlay = LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: min1 - pad1,
        maxY: max1 + pad1,
        backgroundColor: Colors.transparent,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles:
                  SideTitles(showTitles: false, reservedSize: leftReserved)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rightReserved,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                final s = v >= 1000
                    ? '${(v / 1000).toStringAsFixed(0)}k'
                    : v.toStringAsFixed(0);
                return Text(s,
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 9));
              },
            ),
          ),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: false, reservedSize: bottomReserved)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots1,
            isCurved: true,
            color: AppColors.darkTextMuted,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            dashArray: [4, 3],
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      );
    }

    // Legend row
    final ds0Title = ds0['title'] as String? ?? 'Chỉ số';
    final ds1Title = ds1?['title'] as String? ?? 'Giá CP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _LegendDot(color: AppColors.brandPrimaryDark, label: ds0Title),
          if (hasStock) ...[
            const SizedBox(width: 12),
            _LegendDot(
                color: AppColors.darkTextMuted, label: ds1Title, line: true),
          ],
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              LineChart(primary),
              if (stockOverlay != null) LineChart(stockOverlay),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Tab 4: Sức khỏe TC ----------
  Widget _buildHealth() {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () async => Future.wait([_loadGrowth(), _loadSafety()]),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + toggle
                Row(
                  children: [
                    Text('Doanh thu & Lợi nhuận', style: text.titleMedium),
                    const Spacer(),
                    _PeriodToggle(
                      value: _growthPeriod,
                      onChanged: (p) => _loadGrowth(p),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Legend
                Row(children: [
                  _LegendDot(color: AppColors.brandSecondaryDark, label: 'DT'),
                  const SizedBox(width: 8),
                  _LegendDot(color: AppColors.successDark, label: 'LN'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.brandSecondaryDark.withValues(alpha: 0.6), label: '%DT', line: true),
                  const SizedBox(width: 8),
                  _LegendDot(color: AppColors.successDark.withValues(alpha: 0.6), label: '%LN', line: true),
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildGrowthChart(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSafetyCard(),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    final text = Theme.of(context).textTheme;
    if (_loadingSafety) {
      return const FwSkeleton(height: 220, radius: AppRadius.lg);
    }
    if (_errSafety != null && _safety == null) {
      return _SectionError(
          message: 'Không tải được sức khỏe tài chính',
          onRetry: _loadSafety);
    }
    final s = _safety;
    if (s == null) return const SizedBox.shrink();

    final ratios = <(String, String?, Color)>[
      ('ROE', _fmtPct(s['roe']), AppColors.successDark),
      ('ROA', _fmtPct(s['roaa']), AppColors.successDark),
      ('Nợ/VCSH',
          _fmtNum(s['debt_to_equity_latest']), AppColors.brandSecondaryDark),
      ('KN trả lãi',
          _fmtNum(s['interest_coverage']), AppColors.successDark),
      ('CFO/DT', _fmtPct(s['cfo_to_revenue_latest']),
          AppColors.brandSecondaryDark),
      ('CPS', _fmtNum(s['cps'], dec: 0), AppColors.warningDark),
    ];
    final cf = (s['cashflow'] as Map?) ?? const {};

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.darkTextSecondary),
                const SizedBox(width: 6),
                Text('Chỉ số cốt lõi', style: text.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            children: [
              for (final r in ratios)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.darkBorder),
                      bottom: BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.$1,
                          style: text.labelSmall?.copyWith(
                              color: AppColors.darkTextMuted)),
                      const SizedBox(height: 2),
                      Text(r.$2 ?? '—',
                          style: text.titleSmall?.copyWith(color: r.$3)),
                    ],
                  ),
                ),
            ],
          ),
          if (cf.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Dòng tiền (Tỷ VNĐ)',
                  style: text.titleSmall),
            ),
            for (final entry in cf.entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_cfLabel(entry.key.toString()),
                          style: text.bodySmall),
                    ),
                    Text(
                      entry.value == null
                          ? '—'
                          : (entry.value as num).toStringAsFixed(1),
                      style: text.titleSmall,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  static String _cfLabel(String key) => switch (key) {
        'cfo' => 'CFO',
        'cfi' => 'CFI',
        'dividends' => 'Cổ tức trả CSH',
        _ => key,
      };

  static String? _fmtPct(dynamic v) {
    final d = _toD(v);
    return d == null ? null : '${d.toStringAsFixed(1)}%';
  }

  static String? _fmtNum(dynamic v, {int dec = 2}) {
    final d = _toD(v);
    if (d == null) return null;
    final fmt = NumberFormat('#,##0${dec > 0 ? '.${'0' * dec}' : ''}', 'vi_VN');
    return fmt.format(d);
  }

  // ---------- Bottom bar ----------
  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.darkBg,
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: FwButton(
                label: 'Hỏi Mr.Wealth',
                icon: Icons.auto_awesome,
                variant: FwButtonVariant.secondary,
                fullWidth: true,
                onPressed: _openChat,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FwButton(
                label: 'Theo dõi',
                icon: Icons.add,
                fullWidth: true,
                loading: _addingToWatchlist,
                onPressed: _addingToWatchlist ? null : _addToWatchlist,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Charts ----------
  Widget _buildPriceChart() {
    if (_loadingRatio) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errRatio != null && _ratio == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadRatio,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }
    final priceHistory = _ratio?['price_history'] as Map<String, dynamic>?;
    final closeRaw = (priceHistory?['close'] as List<dynamic>?) ?? const [];
    final priceLabels = (priceHistory?['labels'] as List<dynamic>?) ?? const [];
    final price = closeRaw
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
    if (price.isEmpty) {
      return const Center(
          child: Text('Chưa có dữ liệu giá',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final yMin = price.reduce((a, b) => a < b ? a : b);
    final yMax = price.reduce((a, b) => a > b ? a : b);

    double? norm(double? v) {
      if (v == null) return null;
      if (v > yMax * 5 && v >= 1000) return v / 1000.0;
      return v;
    }

    final avgTarget = norm(_toD(_overview?['avg_target_price']));
    Map? techLevels;
    if (!_loadingTechnical && _technical != null) {
      techLevels = ((_technical!['data'] as Map?)?['levels']) as Map?;
    }
    final support = norm(_toD(techLevels?['nearest_support']));
    final resistance = norm(_toD(techLevels?['nearest_resistance']));

    final valSpots = <FlSpot>[];
    if (!_loadingValuationHistory && _valuationHistory != null) {
      final histList = _valuationHistory!['history'] as List<dynamic>? ?? [];
      if (histList.isNotEmpty) {
        // Sort valuation entries by date ascending (DateTime-aware) so we can
        // forward-fill across non-trading dates with a two-pointer walk.
        final entries = <MapEntry<DateTime, double>>[];
        for (final h in histList) {
          final map = h as Map<String, dynamic>;
          final dateStr = map['date'] as String?;
          final val = _toD(map['avg_target_price']);
          if (dateStr == null || val == null) continue;
          final dt = DateTime.tryParse(dateStr);
          if (dt == null) continue;
          entries.add(MapEntry(dt, val));
        }
        entries.sort((a, b) => a.key.compareTo(b.key));

        if (entries.isNotEmpty) {
          final sampleRaw = entries.first.value;
          final lastPrice = price.isNotEmpty ? price.last : 0.0;
          final scale = (sampleRaw > 0 && lastPrice > 0 && sampleRaw < lastPrice / 100) ? 1000.0 : 1.0;
          int ptr = 0;
          double? lastVal;
          for (int i = 0; i < priceLabels.length; i++) {
            final lbl = priceLabels[i].toString();
            final lblDt = DateTime.tryParse(lbl);
            if (lblDt != null) {
              while (ptr < entries.length &&
                  !entries[ptr].key.isAfter(lblDt)) {
                lastVal = norm(entries[ptr].value * scale);
                ptr++;
              }
            }
            if (lastVal != null) {
              valSpots.add(FlSpot(i.toDouble(), lastVal));
            }
          }
        }
      }
    }

    double cMin = yMin;
    double cMax = yMax;
    for (final y in [avgTarget, support, resistance]) {
      if (y != null) {
        if (y < cMin) cMin = y;
        if (y > cMax) cMax = y;
      }
    }
    for (final spot in valSpots) {
      if (spot.y < cMin) cMin = spot.y;
      if (spot.y > cMax) cMax = spot.y;
    }

    final span = (cMax - cMin).abs();
    final pad = span < 0.1 ? 1.0 : span * 0.05;
    final yLo = cMin - pad;
    final yHi = cMax + pad * 4; // extra headroom for labels

    final hLines = <HorizontalLine>[];
    void addHLine(double? y, Color c, String lbl) {
      if (y == null || y <= yLo || y >= yHi) return;
      hLines.add(HorizontalLine(
        y: y,
        color: c,
        strokeWidth: 1.0,
        dashArray: const [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700),
          labelResolver: (_) => lbl,
        ),
      ));
    }

    if (valSpots.isEmpty) {
      addHLine(avgTarget, Colors.orangeAccent, 'ĐG TB');
    }
    addHLine(support, AppColors.successDark, 'HT');
    addHLine(resistance, Colors.redAccent, 'KC');

    // Signal markers placed slightly below the price (web parity: prices[idx]*0.95)
    final labelIndex = <String, int>{};
    for (int i = 0; i < priceLabels.length; i++) {
      labelIndex[priceLabels[i].toString()] = i;
    }
    final signalSpots = <FlSpot>[];
    final signalStrategyMap = <int, List<String>>{};
    final seenIdx = <int>{};
    if (!_loadingSignals) {
      for (final s in _signals) {
        if (s is! Map) continue;
        var date = s['date'] as String?;
        if (date == null) continue;
        date = date.split('T').first;
        var idx = labelIndex[date];
        if (idx == null) {
          final parts = date.split('-');
          if (parts.length == 3) {
            final dmy = '${parts[2]}/${parts[1]}/${parts[0]}';
            idx = labelIndex[dmy];
          }
        }
        if (idx == null || idx >= price.length) continue;
        final strat =
            (s['strategy_name'] ?? s['strategy'] ?? 'Mua').toString();
        signalStrategyMap.putIfAbsent(idx, () => []).add(strat);
        if (!seenIdx.contains(idx)) {
          seenIdx.add(idx);
          signalSpots.add(FlSpot(idx.toDouble(), price[idx] * 0.95));
        }
      }
      signalSpots.sort((a, b) => a.x.compareTo(b.x));
    }

    // Track barIndex → series kind for tooltip rendering
    final priceBarIdx = 0;
    final valBarIdx = valSpots.isNotEmpty ? 1 : -1;
    final signalBarIdx = signalSpots.isNotEmpty
        ? (valSpots.isNotEmpty ? 2 : 1)
        : -1;

    return LineChart(
      LineChartData(
        minY: yLo,
        maxY: yHi,
        extraLinesData: hLines.isEmpty
            ? null
            : ExtraLinesData(horizontalLines: hLines),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.darkBorder.withValues(alpha: 0.4),
            strokeWidth: 0.5,
            dashArray: const [3, 3],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.darkSurface.withValues(alpha: 0.95),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            getTooltipItems: (spots) {
              String? dateText;
              if (spots.isNotEmpty) {
                final i = spots.first.x.toInt();
                if (i >= 0 && i < priceLabels.length) {
                  final raw = priceLabels[i].toString();
                  final dt = DateTime.tryParse(raw);
                  dateText = dt != null
                      ? DateFormat('dd/MM/yyyy').format(dt)
                      : raw;
                }
              }
              bool headerEmitted = false;
              return spots.map((s) {
                LineTooltipItem build(
                    String label, Color color, String value) {
                  final children = <TextSpan>[
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '  $value',
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ];
                  if (!headerEmitted && dateText != null) {
                    headerEmitted = true;
                    return LineTooltipItem(
                      '$dateText\n',
                      const TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      children: children,
                    );
                  }
                  return LineTooltipItem(
                    '',
                    const TextStyle(fontSize: 11),
                    children: children,
                  );
                }

                if (s.barIndex == priceBarIdx) {
                  return build('Giá', AppColors.brandPrimaryDark,
                      s.y.toStringAsFixed(2));
                }
                if (s.barIndex == valBarIdx) {
                  return build('ĐG TB', Colors.orangeAccent,
                      s.y.toStringAsFixed(2));
                }
                if (s.barIndex == signalBarIdx) {
                  final names = signalStrategyMap[s.x.toInt()] ?? const [];
                  final txt = names.isEmpty ? 'Mua' : names.join(', ');
                  return build('Theo dõi', AppColors.successDark, txt);
                }
                return null;
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < price.length; i++)
                FlSpot(i.toDouble(), price[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.18,
            color: AppColors.brandPrimaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimaryDark.withValues(alpha: 0.35),
                  AppColors.brandPrimaryDark.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (valSpots.isNotEmpty)
            LineChartBarData(
              spots: valSpots,
              isCurved: false,
              color: Colors.orangeAccent,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),
          if (signalSpots.isNotEmpty)
            LineChartBarData(
              spots: signalSpots,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) =>
                    _TriangleDotPainter(color: AppColors.successDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValuationChart() {
    if (_loadingRatio) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final r = _ratio;
    if (r == null) {
      return const Center(
          child: Text('Chưa có dữ liệu',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final isPE = _valuationKind == 'PE';
    final raw = (isPE ? r['pe_data'] : r['pb_data']) as List<dynamic>?;
    final ys = (raw ?? const [])
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
    if (ys.isEmpty) {
      return const Center(
          child: Text('Không có dữ liệu định giá',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final color = isPE
        ? AppColors.brandPrimaryDark
        : AppColors.brandSecondaryDark;
    final yMin = ys.reduce((a, b) => a < b ? a : b);
    final yMax = ys.reduce((a, b) => a > b ? a : b);
    final avg = (isPE ? r['avg_pe_1y'] : r['avg_pb_1y']) as num?;
    
    double chartMin = yMin;
    double chartMax = yMax;
    if (avg != null) {
      if (avg < chartMin) chartMin = avg.toDouble();
      if (avg > chartMax) chartMax = avg.toDouble();
    }
    final span = (chartMax - chartMin).abs();
    final pad = span < 0.05 ? 0.5 : span * 0.05;

    return LineChart(
      LineChartData(
        minY: chartMin - pad,
        maxY: chartMax + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.darkBorder.withValues(alpha: 0.4),
            strokeWidth: 0.5,
            dashArray: const [3, 3],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.darkSurface.withValues(alpha: 0.95),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((s) {
                if (s.barIndex == 1) {
                  return LineTooltipItem(
                    'Trung bình: ${s.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return LineTooltipItem(
                  '${isPE ? 'P/E' : 'P/B'}: ${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < ys.length; i++)
                FlSpot(i.toDouble(), ys[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (avg != null)
            LineChartBarData(
              spots: [
                FlSpot(0, avg.toDouble()),
                FlSpot((ys.length - 1).toDouble(), avg.toDouble()),
              ],
              isCurved: false,
              color: Colors.redAccent,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 4],
            ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    if (_loadingGrowth) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_errGrowth != null && _growth == null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: TextButton.icon(
            onPressed: _loadGrowth,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }
    final g = _growth;
    if (g == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Chưa có dữ liệu',
            style: TextStyle(color: AppColors.darkTextMuted))),
      );
    }

    List<String> labels = ((g['labels'] as List?) ?? []).map((e) => e?.toString() ?? '').toList();
    List<double> revenue = ((g['abs_revenue'] as List?) ?? [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble()).toList();
    List<double> profit = ((g['abs_profit'] as List?) ?? [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble()).toList();
    List<double?> revGrowth = ((g['revenue_growth'] as List?) ?? [])
        .map((e) => e == null ? null : (e as num).toDouble()).toList();
    List<double?> profGrowth = ((g['profit_growth'] as List?) ?? [])
        .map((e) => e == null ? null : (e as num).toDouble()).toList();

    if (_growthPeriod == 'year') {
      final currentYear = DateTime.now().year;
      final validIdx = <int>[];
      for (int i = 0; i < labels.length; i++) {
        final lbl = labels[i];
        final dt = DateTime.tryParse(lbl);
        if (dt != null && dt.year >= currentYear) {
          continue;
        }
        validIdx.add(i);
      }
      labels = validIdx.map((i) => labels[i]).toList();
      revenue = validIdx.map((i) => i < revenue.length ? revenue[i] : 0.0).toList();
      profit = validIdx.map((i) => i < profit.length ? profit[i] : 0.0).toList();
      revGrowth = validIdx.map((i) => i < revGrowth.length ? revGrowth[i] : null).toList();
      profGrowth = validIdx.map((i) => i < profGrowth.length ? profGrowth[i] : null).toList();
    }

    if (revenue.isEmpty && profit.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Không có số liệu tăng trưởng',
            style: TextStyle(color: AppColors.darkTextMuted))),
      );
    }

    final n = [revenue.length, profit.length, labels.length]
        .reduce((a, b) => a > b ? a : b);

    String shortLabel(String iso) {
      if (iso.length < 7) return iso;
      final p = iso.split('-');
      if (p.length < 2) return iso;
      final y = p[0].substring(2);
      final m = int.tryParse(p[1]) ?? 0;
      if (_growthPeriod == 'year') return '20$y';
      return 'Q${(m / 3).ceil()}/$y';
    }

    // Shared layout constants — must match exactly between bar and line charts
    // so the plot areas overlap correctly in the Stack.
    const double leftReserved  = 38; // trục trái: giá trị tuyệt đối
    const double rightReserved = 42; // trục phải: % tăng trưởng
    const double bottomReserved = 22;
    const double barW = 6.0;

    // ── Growth % range ────────────────────────────────────────────────────
    final allGrowth = [...revGrowth, ...profGrowth].whereType<double>().toList();
    final gMin = allGrowth.isEmpty ? -50.0
        : (allGrowth.reduce((a, b) => a < b ? a : b) - 15).clamp(-300.0, -10.0);
    final gMax = allGrowth.isEmpty ? 100.0
        : (allGrowth.reduce((a, b) => a > b ? a : b) + 15).clamp(10.0, 400.0);

    FlSpot? toSpot(int i, List<double?> list) {
      if (i >= list.length || list[i] == null) return null;
      return FlSpot(i.toDouble(), list[i]!);
    }
    final revSpots  = [for (int i = 0; i < n; i++) toSpot(i, revGrowth)].whereType<FlSpot>().toList();
    final profSpots = [for (int i = 0; i < n; i++) toSpot(i, profGrowth)].whereType<FlSpot>().toList();
    final hasGrowth = revSpots.isNotEmpty || profSpots.isNotEmpty;

    // ── Bar chart ─────────────────────────────────────────────────────────
    final barData = BarChartData(
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.darkBorder, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: leftReserved,
            getTitlesWidget: (v, meta) {
              if (v == meta.max || v == meta.min) return const SizedBox.shrink();
              final s = v.abs() >= 1000
                  ? '${(v / 1000).toStringAsFixed(0)}k'
                  : v.toStringAsFixed(0);
              return Text(s,
                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9));
            },
          ),
        ),
        // Ẩn right axis — nhường cho LineChart overlay
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: rightReserved),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReserved,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(shortLabel(labels[i]),
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9)),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (int i = 0; i < n; i++)
          BarChartGroupData(x: i, barsSpace: 2, barRods: [
            BarChartRodData(
              toY: i < revenue.length ? revenue[i] : 0,
              width: barW,
              color: AppColors.brandSecondaryDark,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: i < profit.length ? profit[i] : 0,
              width: barW,
              color: AppColors.successDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ]),
      ],
    );

    // ── Line chart overlay ────────────────────────────────────────────────
    final lineData = hasGrowth
        ? LineChartData(
            // minX/maxX căn với spaceAround của bar chart
            minX: -0.5,
            maxX: n - 0.5,
            minY: gMin,
            maxY: gMax,
            clipData: const FlClipData.all(),
            backgroundColor: Colors.transparent,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: v.round() == 0 ? Colors.white30 : Colors.transparent,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              // Ẩn left — nhường cho BarChart
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false, reservedSize: leftReserved),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: rightReserved,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.max || v == meta.min) return const SizedBox.shrink();
                    return Text('${v.toInt()}%',
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 9));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false, reservedSize: bottomReserved),
              ),
            ),
            lineBarsData: [
              if (revSpots.isNotEmpty)
                LineChartBarData(
                  spots: revSpots,
                  isCurved: true,
                  color: AppColors.brandSecondaryDark,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AppColors.brandSecondaryDark, strokeWidth: 0),
                  ),
                  dashArray: [4, 3],
                ),
              if (profSpots.isNotEmpty)
                LineChartBarData(
                  spots: profSpots,
                  isCurved: true,
                  color: AppColors.successDark,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AppColors.successDark, strokeWidth: 0),
                  ),
                  dashArray: [4, 3],
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.darkSurface,
                getTooltipItems: (spots) => spots.map((s) {
                  final sign = s.y >= 0 ? '+' : '';
                  return LineTooltipItem(
                    '$sign${s.y.toStringAsFixed(1)}%',
                    TextStyle(color: s.bar.color, fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
          )
        : null;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          BarChart(barData),
          if (lineData != null) LineChart(lineData),
        ],
      ),
    );
  }
}

// ===== Helpers =====

class _VcStyle {
  final IconData iconData;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color pillBg;
  final Color pillText;
  const _VcStyle({
    required this.iconData,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.pillBg,
    required this.pillText,
  });
}

class _ChartPeriodBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChartPeriodBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                active ? Colors.white : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.darkTextMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.brandPrimaryDark,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _RangePill({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.brandPrimary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: active
                  ? AppColors.brandPrimaryDark
                  : AppColors.darkBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? AppColors.brandPrimaryDark
                  : AppColors.darkTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool isDashed;
  const _LegendDot({
    required this.color,
    required this.label,
    this.line = false,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDashed
            ? Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Container(width: 4, height: 2, color: color),
                    if (i < 2) const SizedBox(width: 2),
                  ],
                ],
              )
            : line
                ? Container(width: 14, height: 2, color: color)
                : Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.darkTextSecondary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PeriodToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('Quý', 'quarter'),
          _btn('Năm', 'year'),
        ],
      ),
    );
  }

  Widget _btn(String label, String period) {
    final active = value == period;
    return GestureDetector(
      onTap: () => onChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.darkTextMuted,
            )),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  final String label;
  final bool alignRight;
  const _TableHead(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.darkTextMuted,
      ),
    );
  }
}

class _OpportunityRiskCard extends StatelessWidget {
  final double opportunity;
  final double risk;
  final double faScore;
  final double? upside;
  final Map<String, dynamic>? insight;

  const _OpportunityRiskCard({
    required this.opportunity,
    required this.risk,
    required this.faScore,
    this.upside,
    this.insight,
  });

  Color get _oppColor {
    if (opportunity >= 65) return const Color(0xFF22C55E);
    if (opportunity >= 50) return AppColors.brandPrimary;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final oppInt = opportunity.round();
    final riskInt = risk.round();

    return FwCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 12, color: AppColors.brandPrimaryDark),
              const SizedBox(width: 6),
              Text('Cơ hội & Rủi ro',
                  style: text.titleSmall?.copyWith(fontSize: 12)),
              if (insight != null && insight!['updated_at'] != null && insight!['updated_at'].toString().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('(${insight!['updated_at']})',
                    style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
              ],
              const Spacer(),
              if (upside == null)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.2, color: AppColors.darkTextMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$oppInt%',
                    style: text.titleSmall?.copyWith(
                      color: _oppColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text('Cơ hội',
                      style: text.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted, fontSize: 9)),
                ],
              ),
              const Spacer(),
              if (upside != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        upside! >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 10,
                        color: upside! >= 0
                            ? AppColors.successDark
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Upside: ${upside! >= 0 ? '+' : ''}${upside!.toStringAsFixed(1)}%',
                        style: text.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: upside! >= 0
                              ? AppColors.successDark
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$riskInt%',
                    style: text.titleSmall?.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text('Rủi ro',
                      style: text.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  Expanded(
                    flex: oppInt,
                    child: Container(color: _oppColor),
                  ),
                  Expanded(
                    flex: riskInt,
                    child: Container(
                        color: Colors.redAccent.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
          if (insight != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.darkBorder),
            const SizedBox(height: AppSpacing.sm),
            _buildInsightList(
                insight!['opportunities'] as List<dynamic>?, true),
            _buildInsightList(insight!['risks'] as List<dynamic>?, false),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightList(List<dynamic>? items, bool isOpp) {
    if (items == null || items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          isOpp ? 'Chưa có dữ liệu từ CTCK' : 'Không phát hiện rủi ro đáng kể',
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkTextMuted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final text = item.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0, right: 6.0),
                child: Icon(
                  isOpp ? Icons.check : Icons.warning_amber_rounded,
                  size: 14,
                  color: isOpp ? AppColors.successDark : Colors.redAccent,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TriangleDotPainter extends FlDotPainter {
  final Color color;
  final double size;

  const _TriangleDotPainter({required this.color, this.size = 7.0});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset center) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx - size * 0.75, center.dy + size * 0.5)
      ..lineTo(center.dx + size * 0.75, center.dy + size * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  Size getSize(FlSpot spot) => Size(size * 2, size * 2);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _TriangleDotPainter && b is _TriangleDotPainter) {
      return _TriangleDotPainter(
        color: Color.lerp(a.color, b.color, t)!,
        size: a.size + (b.size - a.size) * t,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [color, size];
}
