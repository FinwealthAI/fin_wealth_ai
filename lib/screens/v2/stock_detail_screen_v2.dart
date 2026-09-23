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

part 'stock_detail/overview_tab.dart';
part 'stock_detail/valuation_tab.dart';
part 'stock_detail/value_chain_tab.dart';
part 'stock_detail/quant_tab.dart';
part 'stock_detail/forecast_tab.dart';
part 'stock_detail/health_tab.dart';
part 'stock_detail/charts.dart';
part 'stock_detail/widgets.dart';

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

  Map<String, dynamic>? _quant;
  bool _loadingQuant = true;
  Object? _errQuant;

  Map<String, dynamic>? _forecast;
  bool _loadingForecast = true;
  Object? _errForecast;
  int _selectedChartIdx = 0;
  int _chartPeriodDays = 365; // 180 | 365 | 1095 | -1 (all)

  bool _loadingOverview = true,
      _loadingValuation = true,
      _loadingValuationHistory = true,
      _loadingRatio = true,
      _loadingGrowth = true,
      _loadingSafety = true,
      _loadingSignals = true,
      _loadingTechnical = true;
  Object? _errOverview, _errValuation, _errRatio, _errGrowth, _errSafety;

  List<dynamic> _signals = [];

  bool _addingToWatchlist = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
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
      _loadingChain = false;
      _loadingQuant = false;
      _loadingForecast = false;
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
      _loadQuant(),
      _loadForecast(),
    ]);
  }

  Future<void> _loadQuant() async {
    setState(() {
      _loadingQuant = true;
      _errQuant = null;
    });
    try {
      final d = await _repo.getQuantScores(widget.ticker);
      if (!mounted) return;
      setState(() {
        _quant = d;
        _loadingQuant = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errQuant = e;
        _loadingQuant = false;
      });
    }
  }

  Future<void> _loadForecast() async {
    setState(() {
      _loadingForecast = true;
      _errForecast = null;
    });
    try {
      final d = await _repo.getForecast(widget.ticker);
      if (!mounted) return;
      setState(() {
        _forecast = d;
        _loadingForecast = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errForecast = e;
        _loadingForecast = false;
      });
    }
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
    try {
      final d = await _repo.getInsight(widget.ticker);
      if (!mounted) return;
      setState(() => _insight = d);
    } catch (_) {
      // Insight chỉ dùng cho nhãn `updated_at`; lỗi thì bỏ qua.
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
    setState(() => _loadingValuationHistory = true);
    try {
      final d = await _repo.getValuationHistory(widget.ticker);
      if (!mounted) return;
      setState(() {
        _valuationHistory = d;
        _loadingValuationHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingValuationHistory = false);
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
            isGuest ? _guestTab() : _buildForecast(),
            isGuest ? _guestTab() : _buildValueChain(),
            isGuest ? _guestTab() : _buildHealth(),
            isGuest ? _guestTab() : _buildQuant(),
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
    // change == null (chưa tải/khách): trung tính, tránh tô xanh mặc định lên "—".
    final priceColor = change == null
        ? AppColors.darkTextPrimary
        : (positive ? AppColors.successDark : AppColors.dangerDark);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 252,
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
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        // Đáy chừa kTextTabBarHeight (46) vì flexibleSpace trải
                        // hết cả vùng TabBar → không chừa sẽ đè lên hàng tab.
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 56, AppSpacing.lg, 58),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
          Tab(text: 'Dự báo'),
          Tab(text: 'Chuỗi GT'),
          Tab(text: 'Sức khỏe'),
          Tab(text: 'Định lượng'),
        ],
      ),
    );
  }


  /// setState là @protected — các extension trong part files (tab/chart)
  /// rebuild qua helper này.
  void _rebuild(VoidCallback fn) => setState(fn);

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
}

// ===== Helpers to read API fields safely =====
// Top-level (không phải static member) để các part files gọi không cần qualify.
double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final cleaned = v.replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned);
  }
  return null;
}
