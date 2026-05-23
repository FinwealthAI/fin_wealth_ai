import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/api_config.dart';
import '../../models/investment_opportunities.dart';
import '../../respositories/auth_repository.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import 'stock_detail_screen_v2.dart';

class StrategyDetailScreenV2 extends StatefulWidget {
  final StrategyCardData card;
  const StrategyDetailScreenV2({super.key, required this.card});

  @override
  State<StrategyDetailScreenV2> createState() => _StrategyDetailScreenV2State();
}

class _StrategyDetailScreenV2State extends State<StrategyDetailScreenV2>
    with SingleTickerProviderStateMixin {
  late final InvestmentOpportunitiesRepository _repo =
      context.read<InvestmentOpportunitiesRepository>();
  late final AuthRepository _auth = context.read<AuthRepository>();

  late StrategyCardData _card = widget.card;
  late bool _isFollowing = widget.card.isFollowing;
  bool _followLoading = false;

  // Full data from /detail/
  bool _loadingDetail = true;
  Map<String, dynamic>? _detail;

  // Stats from /stats/
  bool _loadingStats = true;
  Map<String, dynamic>? _stats;

  late TabController _tabController;

  // Ưu tiên giá trị từ detail endpoint (đọc trực tiếp từ DB) nếu đã có
  bool get _showPerf =>
      _detail != null ? (_detail!['show_performance'] as bool? ?? false) : _card.showPerformance;

  @override
  void initState() {
    super.initState();
    final tabCount = _showPerf ? 4 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadCard(),
      _loadDetail(),
      if (_showPerf) _loadStats(),
    ]);
  }

  Future<void> _loadCard() async {
    if (_card.presetId == 0) return;
    try {
      final full = await _repo.fetchStrategyCard(_card.presetId);
      if (!mounted) return;
      if (full != null) {
        final prevShowPerf = _card.showPerformance;
        setState(() {
          _card = full;
          _isFollowing = full.isFollowing;
        });
        // Tái tạo TabController nếu show_performance thay đổi
        if (prevShowPerf != full.showPerformance) {
          final old = _tabController;
          final newCount = full.showPerformance ? 4 : 1;
          setState(() {
            _tabController = TabController(length: newCount, vsync: this);
          });
          old.dispose();
          // Load stats nếu show_performance vừa bật lên
          if (full.showPerformance && mounted) _loadStats();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDetail() async {
    if (_card.presetId == 0) {
      setState(() => _loadingDetail = false);
      return;
    }
    try {
      final d = await _repo.fetchStrategyDetail(_card.presetId);
      if (!mounted) return;
      // Dùng show_performance từ detail endpoint làm nguồn chính xác nhất
      final detailShowPerf = d?['show_performance'] as bool? ?? false;
      final prevShowPerf = _showPerf;
      setState(() => _detail = d);
      if (prevShowPerf != detailShowPerf) {
        final old = _tabController;
        final newCount = detailShowPerf ? 4 : 1;
        setState(() {
          _tabController = TabController(length: newCount, vsync: this);
        });
        old.dispose();
        if (detailShowPerf && mounted) _loadStats();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDetail = false);
  }

  Future<void> _loadStats() async {
    if (_card.presetId == 0) {
      setState(() => _loadingStats = false);
      return;
    }
    try {
      final s = await _repo.fetchStrategyStats(_card.presetId);
      if (!mounted) return;
      setState(() => _stats = s);
    } catch (_) {}
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _toggleFollow() async {
    if (_auth.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để theo dõi chiến lược')),
      );
      return;
    }
    setState(() => _followLoading = true);
    final ok = _isFollowing
        ? await _repo.unfollowStrategy(_card.presetId)
        : await _repo.followStrategy(_card.presetId);
    if (!mounted) return;
    if (ok) setState(() => _isFollowing = !_isFollowing);
    setState(() => _followLoading = false);
  }

  bool get _isAi => (_card.ownerUsername ?? '').toUpperCase() == 'AI';
  bool get _isTechnical => (_card.filterType ?? '').toUpperCase() == 'TECHNICAL';
  IconData get _stratIcon => _isTechnical ? Icons.memory : Icons.diamond_outlined;
  Color get _stratColor =>
      _isTechnical ? AppColors.brandSecondaryDark : const Color(0xFF9B59B6);

  @override
  Widget build(BuildContext context) {
    final tabs = _showPerf
        ? const ['Thống kê', 'Danh sách theo dõi', 'Lịch sử', 'Đánh giá']
        : const ['Đánh giá'];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkTextPrimary),
        title: Text(
          _card.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: _buildHeader(),
          ),
          // Tab bar
          Container(
            color: AppColors.darkSurface,
            child: TabBar(
              controller: _tabController,
              isScrollable: tabs.length > 3,
              indicatorColor: AppColors.brandPrimaryDark,
              indicatorWeight: 2,
              labelColor: AppColors.brandPrimaryDark,
              unselectedLabelColor: AppColors.darkTextMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _showPerf
                  ? [
                      _buildStatsTab(),
                      _buildActiveTab(),
                      _buildHistoryTab(),
                      _buildReviewTab(),
                    ]
                  : [_buildReviewTab()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!_card.isOwned && _auth.accessToken != null)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 48,
                  child: _followLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildFollowButton(),
                ),
              ),
            )
          : null,
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final text = Theme.of(context).textTheme;
    final perf = _card.perfYear;
    final showPerf = _card.showPerformance && perf != null;
    final perfPositive = (perf ?? 0) >= 0;
    final perfColor = perfPositive ? AppColors.successDark : AppColors.dangerDark;

    return Container(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _stratColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(_stratIcon, size: 20, color: _stratColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_card.title,
                        style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimaryDark)),
                    if (_card.author != null)
                      Row(children: [
                        if (_card.ownerAvatar != null &&
                            _card.ownerAvatar!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ClipOval(
                              child: Image.network(
                                _card.ownerAvatar!.startsWith('http')
                                    ? _card.ownerAvatar!
                                    : '${ApiConfig.websiteUrl}${_card.ownerAvatar}',
                                width: 14,
                                height: 14,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 12,
                                    color: AppColors.darkTextMuted),
                              ),
                            ),
                          ),
                        Text(_card.author ?? '',
                            style: text.labelSmall
                                ?.copyWith(color: AppColors.darkTextSecondary)),
                      ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 4, runSpacing: 4, children: [
            if (_isAi)
              _Badge(label: 'AI Advisor', color: const Color(0xFF9B59B6), filled: true),
            _Badge(
              icon: _isTechnical ? Icons.memory : Icons.bar_chart,
              label: _isTechnical ? 'Định lượng' : 'Cơ bản',
              color: _isTechnical ? AppColors.brandSecondaryDark : AppColors.successDark,
            ),
            if (_card.hasAutoExit)
              const _Badge(
                  icon: Icons.shield_outlined,
                  label: 'Auto exit',
                  color: AppColors.successDark),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Chip(
                icon: Icons.candlestick_chart,
                label: '${_card.tickerCount} mã',
                color: AppColors.brandPrimaryDark),
            const SizedBox(width: 8),
            _Chip(
                icon: Icons.people_outline,
                label: '${_card.followerCount} follow',
                color: AppColors.brandSecondaryDark),
            if (showPerf) ...[
              const SizedBox(width: 8),
              _Chip(
                icon: perfPositive ? Icons.arrow_upward : Icons.arrow_downward,
                label: '1Y ${perfPositive ? "+" : ""}${perf.toStringAsFixed(1)}%',
                color: perfColor,
              ),
            ],
          ]),
          if ((_card.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text((_card.description ?? '').trim(),
                style: text.bodySmall?.copyWith(color: AppColors.darkTextSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ─── Tab: Thống kê ─────────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    final stats = _stats;
    if (stats == null) {
      return _emptyState(Icons.bar_chart, 'Chưa có dữ liệu thống kê');
    }

    final perf = stats['perf_cards'] as Map? ?? {};
    final s = stats['stats'] as Map? ?? {};

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Performance cards row
        _sectionTitle('Hiệu suất'),
        const SizedBox(height: 8),
        Row(children: [
          _PerfCard(label: 'Ngày', value: _toD(perf['day'])),
          const SizedBox(width: 8),
          _PerfCard(label: 'Tuần', value: _toD(perf['week'])),
          const SizedBox(width: 8),
          _PerfCard(label: 'Tháng', value: _toD(perf['month'])),
          const SizedBox(width: 8),
          _PerfCard(label: '3 Tháng', value: _toD(perf['three_month'])),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle('Tổng quan'),
        const SizedBox(height: 8),
        _statCard([
          _StatRow(label: 'Tổng hiệu suất', value: '${_fmtPct(_toD(s['total_return']))}'),
          _StatRow(label: 'Win rate TB', value: '${_fmtPct(_toD(s['win_rate']))}'),
          _StatRow(label: 'Tổng vị thế', value: '${(s['total_trades'] ?? 0).toInt()}'),
          _StatRow(label: 'Đang theo dõi', value: '${(s['active_trades'] ?? 0).toInt()}'),
        ]),
        // Backtest metrics from card
        if (_card.backtestMetrics != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('Backtest AI Calibrated'),
          const SizedBox(height: 8),
          _buildBacktestMetrics(_card.backtestMetrics!),
        ],
      ],
    );
  }

  Widget _buildBacktestMetrics(Map<String, dynamic> m) {
    return _statCard([
      _StatRow(label: 'Win Rate', value: '${_fmtPct(_toD(m['win_rate']))}'),
      _StatRow(label: 'Expectancy/vị thế', value: '${_fmtPct(_toD(m['expectancy_pct']))}'),
      _StatRow(label: 'Avg Hold Days', value: '${_toD(m['avg_hold_days'])?.toStringAsFixed(1) ?? "--"} ngày'),
      _StatRow(label: 'Tổng vị thế BT', value: '${m['total_trades'] ?? "--"}'),
      _StatRow(label: 'Sharpe Ratio', value: _toD(m['sharpe_ratio'])?.toStringAsFixed(2) ?? '--'),
      _StatRow(label: 'Max Drawdown', value: m['max_drawdown'] != null ? '-${_toD(m['max_drawdown'])!.toStringAsFixed(1)}%' : '--'),
    ]);
  }

  // ─── Tab: Tín hiệu mở ──────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    final positions = (_detail?['active_positions'] as List?) ?? [];
    if (positions.isEmpty) {
      return _emptyState(Icons.show_chart_outlined, 'Hiện không có mã nào đang theo dõi');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: positions.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.darkBorder),
      itemBuilder: (_, i) {
        final p = Map<String, dynamic>.from(positions[i] as Map);
        return _PositionRow(
          ticker: p['ticker']?.toString() ?? '',
          date: p['entry_date']?.toString() ?? '',
          entryPrice: _toD(p['entry_price']),
          pnlPct: _toD(p['pnl_pct']),
          stopLoss: _toD(p['stop_loss']),
          takeProfit: _toD(p['take_profit']),
          isClosed: false,
          onTap: () => _openStock(p['ticker']?.toString() ?? ''),
        );
      },
    );
  }

  // ─── Tab: Lịch sử ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    final positions = (_detail?['closed_positions'] as List?) ?? [];
    if (positions.isEmpty) {
      return _emptyState(Icons.history, 'Chưa có lịch sử theo dõi');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: positions.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.darkBorder),
      itemBuilder: (_, i) {
        final p = Map<String, dynamic>.from(positions[i] as Map);
        return _PositionRow(
          ticker: p['ticker']?.toString() ?? '',
          date: '${p['entry_date'] ?? ''} → ${p['exit_date'] ?? ''}',
          entryPrice: _toD(p['entry_price']),
          exitPrice: _toD(p['exit_price']),
          pnlPct: _toD(p['pnl_pct']),
          isClosed: true,
          onTap: () => _openStock(p['ticker']?.toString() ?? ''),
        );
      },
    );
  }

  // ─── Tab: Đánh giá ─────────────────────────────────────────────────────────

  Widget _buildReviewTab() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    final reviews = (_detail?['reviews'] as List?) ?? [];
    final avgRating = _toD(_detail?['avg_rating']) ?? 0;
    final reviewCount = (_detail?['review_count'] as num?)?.toInt() ?? 0;
    final userReview = _detail?['user_review'] as Map?;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPrimaryDark),
                  ),
                  _StarRow(rating: avgRating.round()),
                  const SizedBox(height: 4),
                  Text('$reviewCount đánh giá',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkTextMuted)),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              // Write review
              Expanded(child: _buildWriteReview(userReview)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (reviews.isEmpty)
          _emptyState(Icons.chat_bubble_outline, 'Chưa có đánh giá nào')
        else
          ...reviews.map((r) {
            final rv = Map<String, dynamic>.from(r as Map);
            return _ReviewCard(
              username: rv['username']?.toString() ?? 'Ẩn danh',
              rating: (rv['rating'] as num?)?.toInt() ?? 5,
              comment: rv['comment']?.toString() ?? '',
              date: rv['updated_at']?.toString() ?? '',
            );
          }),
      ],
    );
  }

  Widget _buildWriteReview(Map? existing) {
    if (_auth.accessToken == null) {
      return const Text('Đăng nhập để đánh giá',
          style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted));
    }
    return _ReviewForm(
      initialRating: (existing?['rating'] as num?)?.toInt() ?? 5,
      initialComment: existing?['comment']?.toString() ?? '',
      onSubmit: (rating, comment) async {
        final ok = await _repo.submitStrategyReview(
            _card.presetId, rating, comment);
        if (!mounted) return;
        if (ok) {
          setState(() => _loadingDetail = true);
          await _loadDetail();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gửi đánh giá thất bại')),
          );
        }
      },
    );
  }

  // ─── Ticker list (inside Thống kê if show_perf=false, or standalone) ───────

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _openStock(String ticker) {
    if (ticker.isEmpty) return;
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StockDetailScreenV2(ticker: ticker)));
  }

  Widget _buildFollowButton() {
    if (_isFollowing) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.successDark),
          foregroundColor: AppColors.successDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: _toggleFollow,
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text('Đang theo dõi'),
      );
    }
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: _toggleFollow,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Theo dõi chiến lược'),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextSecondary,
          letterSpacing: 0.5));

  Widget _statCard(List<_StatRow> rows) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: rows
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Text(r.label,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.darkTextMuted)),
                      const Spacer(),
                      Text(r.value,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkTextPrimary)),
                    ]),
                  ))
              .toList(),
        ),
      );

  Widget _emptyState(IconData icon, String msg) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppColors.darkTextMuted),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13)),
        ]),
      );

  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _fmtPct(double? v) {
    if (v == null) return '--';
    return '${v >= 0 ? "+" : ""}${v.toStringAsFixed(1)}%';
  }
}

// ─── Small helper widgets ──────────────────────────────────────────────────────

class _StatRow {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});
}

class _PerfCard extends StatelessWidget {
  final String label;
  final double? value;
  const _PerfCard({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final pos = v >= 0;
    final color = pos ? AppColors.successDark : AppColors.dangerDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text('${pos ? "+" : ""}${v.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.darkTextMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  final String ticker;
  final String date;
  final double? entryPrice;
  final double? exitPrice;
  final double? pnlPct;
  final double? stopLoss;
  final double? takeProfit;
  final bool isClosed;
  final VoidCallback? onTap;

  const _PositionRow({
    required this.ticker,
    required this.date,
    this.entryPrice,
    this.exitPrice,
    this.pnlPct,
    this.stopLoss,
    this.takeProfit,
    required this.isClosed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pnl = pnlPct ?? 0;
    final pos = pnl >= 0;
    final pnlColor = pos ? AppColors.successDark : AppColors.dangerDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          // Ticker
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryDark.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(ticker,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimaryDark)),
          ),
          const SizedBox(width: 10),
          // Date + prices
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.darkTextMuted)),
                const SizedBox(height: 2),
                if (!isClosed && (stopLoss != null || takeProfit != null))
                  Row(children: [
                    if (stopLoss != null)
                      Text('SL ${stopLoss!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.dangerDark)),
                    if (stopLoss != null && takeProfit != null)
                      const Text('  ',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.darkBorder)),
                    if (takeProfit != null)
                      Text('TP ${takeProfit!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.successDark)),
                  ])
                else if (isClosed && entryPrice != null)
                  Text(
                    '${entryPrice!.toStringAsFixed(2)} → ${exitPrice?.toStringAsFixed(2) ?? "--"}',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.darkTextMuted),
                  ),
              ],
            ),
          ),
          // PnL
          Text(
            '${pos ? "+" : ""}${pnl.toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: pnlColor),
          ),
        ]),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String username;
  final int rating;
  final String comment;
  final String date;
  const _ReviewCard(
      {required this.username,
      required this.rating,
      required this.comment,
      required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  AppColors.brandPrimaryDark.withValues(alpha: 0.15),
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimaryDark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  _StarRow(rating: rating, size: 10),
                ],
              ),
            ),
            Text(date,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkTextMuted)),
          ]),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
          ],
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.warningDark,
        );
      }),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  final int initialRating;
  final String initialComment;
  final Future<void> Function(int rating, String comment) onSubmit;
  const _ReviewForm(
      {required this.initialRating,
      required this.initialComment,
      required this.onSubmit});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.initialRating;
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialComment);
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đánh giá của bạn',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextSecondary)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Icon(
                i < _rating ? Icons.star : Icons.star_border,
                size: 22,
                color: AppColors.warningDark,
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 12, color: AppColors.darkTextPrimary),
          decoration: InputDecoration(
            hintText: 'Nhận xét...',
            hintStyle: const TextStyle(
                fontSize: 12, color: AppColors.darkTextMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.brandPrimaryDark),
            ),
            filled: true,
            fillColor: AppColors.darkBg,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    await widget.onSubmit(_rating, _ctrl.text.trim());
                    if (mounted) setState(() => _loading = false);
                  },
            child: _loading
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Gửi', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool filled;
  const _Badge({this.icon, required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : color.withValues(alpha: 0.12);
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
