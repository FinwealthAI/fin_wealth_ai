import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _safety;

  bool _loadingOverview = true,
      _loadingValuation = true,
      _loadingRatio = true,
      _loadingGrowth = true,
      _loadingSafety = true;
  Object? _errOverview, _errValuation, _errRatio, _errGrowth, _errSafety;

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
      _loadingRatio = false;
      _loadingGrowth = false;
      _loadingSafety = false;
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
      _loadRatio(),
      _loadGrowth(),
      _loadSafety(),
    ]);
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

  Future<void> _loadGrowth() async {
    setState(() {
      _loadingGrowth = true;
      _errGrowth = null;
    });
    try {
      final d = await _repo.getGrowth(widget.ticker);
      if (!mounted) return;
      setState(() {
        _growth = d;
        _loadingGrowth = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errGrowth = e;
        _loadingGrowth = false;
      });
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
      expandedHeight: 240,
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
                  Text(price.toStringAsFixed(2),
                      style:
                          text.titleSmall?.copyWith(color: priceColor)),
                ],
                if (change != null) ...[
                  const SizedBox(width: 6),
                  Text(
                      '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 56, AppSpacing.lg, 56),
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
                              style: text.bodyMedium?.copyWith(
                                  color: AppColors.darkTextSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price == null ? '—' : price.toStringAsFixed(2),
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
                                          '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
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
                  children: const [
                    _LegendDot(
                        color: AppColors.brandPrimaryDark,
                        label: 'Giá đóng cửa'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildOverviewKpiGrid(),
        ],
      ),
    );
  }

  Widget _buildOverviewKpiGrid() {
    final text = Theme.of(context).textTheme;
    if (_loadingOverview) {
      return const FwSkeleton(height: 140, radius: AppRadius.lg);
    }
    if (_errOverview != null && _overview == null) {
      return _SectionError(
          message: 'Không tải được tổng quan', onRetry: _loadOverview);
    }
    final o = _overview;
    if (o == null) return const SizedBox.shrink();

    final fields = <(String, String?)>[
      ('Giá', o['price']?.toString()),
      ('Tăng/Giảm (%)', o['up_size']?.toString()),
      ('P/E', o['price_to_earnings']?.toString()),
      ('P/B', o['price_to_book']?.toString()),
      ('EPS', o['eps_tr']?.toString()),
      ('Cổ tức (%)', o['dividend_yield']?.toString()),
    ];

    return FwCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Thông tin nhanh', style: text.titleMedium),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            children: [
              for (final f in fields)
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
                      Text(f.$1,
                          style: text.labelSmall
                              ?.copyWith(color: AppColors.darkTextMuted)),
                      const SizedBox(height: 2),
                      Text(
                          f.$2 == null || f.$2 == 'null' || f.$2!.isEmpty
                              ? '—'
                              : f.$2!,
                          style: text.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ],
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
                  Expanded(flex: 3, child: _TableHead('Tổ chức')),
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
            flex: 3,
            child: Row(
              children: [
                FwBadge(label: firm, tone: FwBadgeTone.info),
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
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        FwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 16, color: AppColors.brandPrimaryDark),
                  const SizedBox(width: 6),
                  Text('Chuỗi giá trị', style: text.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bản đồ chuỗi giá trị chi tiết hiện chỉ có trên web. Truy cập finwealth.vn → Sơ đồ kinh tế của ${widget.ticker} để xem.',
                style: text.bodySmall,
              ),
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
      onRefresh: () async {
        await Future.wait([_loadGrowth(), _loadSafety()]);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Doanh thu & Lợi nhuận', style: text.titleMedium),
                    const Spacer(),
                    _LegendDot(
                        color: AppColors.brandSecondaryDark, label: 'DT'),
                    const SizedBox(width: 8),
                    _LegendDot(
                        color: AppColors.successDark, label: 'LN'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Số thực tế (Tỷ VNĐ)', style: text.labelSmall),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 180, child: _buildGrowthChart()),
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
      ('ROE', _fmtPct(s['roae']), AppColors.successDark),
      ('ROA', _fmtPct(s['roaa']), AppColors.successDark),
      ('Nợ/VCSH',
          _fmtNum(s['debt_to_equity_latest']), AppColors.brandSecondaryDark),
      ('KN trả lãi',
          _fmtNum(s['interest_coverage']), AppColors.successDark),
      ('CFO/DT', _fmtPct(s['cfo_to_revenue_latest']),
          AppColors.brandSecondaryDark),
      ('CPS', _fmtNum(s['cps']), AppColors.warningDark),
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

  static String? _fmtNum(dynamic v) {
    final d = _toD(v);
    return d == null ? null : d.toStringAsFixed(2);
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
    final span = (yMax - yMin).abs();
    final pad = span < 0.1 ? 1 : span * 0.05;

    return LineChart(
      LineChartData(
        minY: yMin - pad,
        maxY: yMax + pad,
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
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      'Giá  ${s.y.toStringAsFixed(2)}',
                      const TextStyle(
                        color: AppColors.brandPrimaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
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
    final span = (yMax - yMin).abs();
    final pad = span < 0.05 ? 0.5 : span * 0.05;

    return LineChart(
      LineChartData(
        minY: yMin - pad,
        maxY: yMax + pad,
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
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${isPE ? 'P/E' : 'P/B'}  ${s.y.toStringAsFixed(2)}',
                      TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
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
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    if (_loadingGrowth) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errGrowth != null && _growth == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadGrowth,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }
    final g = _growth;
    if (g == null) {
      return const Center(
          child: Text('Chưa có dữ liệu',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final revenue = ((g['abs_revenue'] as List<dynamic>?) ?? const [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble())
        .toList();
    final profit = ((g['abs_profit'] as List<dynamic>?) ?? const [])
        .map((e) => e == null ? 0.0 : (e as num).toDouble())
        .toList();
    if (revenue.isEmpty && profit.isEmpty) {
      return const Center(
          child: Text('Không có số liệu tăng trưởng',
              style: TextStyle(color: AppColors.darkTextMuted)));
    }
    final n = revenue.length > profit.length ? revenue.length : profit.length;

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (int i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: i < revenue.length ? revenue[i] : 0,
                  width: 7,
                  color: AppColors.brandSecondaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: i < profit.length ? profit[i] : 0,
                  width: 7,
                  color: AppColors.successDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ===== Helpers =====

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
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
