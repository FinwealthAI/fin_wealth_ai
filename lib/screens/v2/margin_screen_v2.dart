import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class MarginStock {
  String ticker;
  double q;
  double qPending;
  double price; // in VNĐ (e.g. 25500)
  double cPercent; // 0..100
  double imPercent; // 0..100
  double? al;

  MarginStock({
    this.ticker = '',
    this.q = 0,
    this.qPending = 0,
    this.price = 0,
    this.cPercent = 0,
    this.imPercent = 100,
    this.al,
  });

  MarginStock clone() => MarginStock(
        ticker: ticker,
        q: q,
        qPending: qPending,
        price: price,
        cPercent: cPercent,
        imPercent: imPercent,
        al: al,
      );
}

class MarginResult {
  final double a, cv, cvPending, e, im, mm, ee, surplus, mr, mc, alTotal;
  final double c;

  const MarginResult({
    required this.c,
    required this.a,
    required this.cv,
    required this.cvPending,
    required this.e,
    required this.im,
    required this.mm,
    required this.ee,
    required this.surplus,
    required this.mr,
    required this.mc,
    required this.alTotal,
  });

  bool get isCall => surplus < 0;
  bool get hasMargin => im > 0;
}

enum SimType { deposit, withdraw, buy, sell }

class SimLog {
  final int id;
  final SimType type;
  double? amount;
  String? ticker;
  double? q;
  double? price;
  double? c;
  double? im;

  SimLog({
    required this.id,
    required this.type,
    this.amount,
    this.ticker,
    this.q,
    this.price,
    this.c,
    this.im,
  });
}

// ─── Calculator logic (ported from web JS) ────────────────────────────────────

MarginResult computeMargin(
  double C,
  double mmRatio, // 0..1
  double xRatio,  // 0..1
  List<MarginStock> stocks,
) {
  double a = 0, cv = 0, cvPending = 0, im = 0, alTotal = 0;
  for (final stk in stocks) {
    final val = stk.q * stk.price;
    final valPending = stk.qPending * stk.price;
    a += val + valPending;
    if (stk.al != null) alTotal += stk.al!;

    final c_ = stk.cPercent / 100;
    final im_ = stk.imPercent / 100;

    final cvStk = c_ > 0 ? val * c_ : 0.0;
    final cvPend = valPending * c_;
    cvPending += cvPend;
    cv += cvStk + cvPend;

    if (c_ > 0 || cvPend > 0) {
      double imStk = cvStk * im_;
      final imPend = cvPend * 1.0; // 100% for pending
      final loan = cvStk - imStk;
      if (stk.al != null && loan > stk.al!) {
        imStk = cvStk - stk.al!;
      }
      im += imStk + imPend;
    }
  }

  final e = C + cv;
  final mm = im * mmRatio;
  final ee = e - im;
  final surplus = e - mm;
  final mr = im > 0 ? e / im : (e > 0 ? 9999.0 : 0.0);
  final mc = surplus < 0 ? (mm * xRatio) - e : 0.0;

  return MarginResult(
    c: C,
    a: a,
    cv: cv,
    cvPending: cvPending,
    e: e,
    im: im,
    mm: mm,
    ee: ee,
    surplus: surplus,
    mr: mr,
    mc: mc,
    alTotal: alTotal,
  );
}

({double simC, List<MarginStock> simStocks, MarginResult res}) applySimulation(
  double baseC,
  double mmRatio,
  double xRatio,
  List<MarginStock> baseStocks,
  List<SimLog> logs,
) {
  double simC = baseC;
  final simStocks = baseStocks.map((s) => s.clone()).toList();

  for (final log in logs) {
    switch (log.type) {
      case SimType.deposit:
        simC += log.amount!;
      case SimType.withdraw:
        simC -= log.amount!;
      case SimType.sell:
        simC += log.q! * log.price!;
        final idx = simStocks.indexWhere((s) => s.ticker == log.ticker);
        if (idx >= 0) {
          simStocks[idx].q -= log.q!;
          if (simStocks[idx].q <= 0) simStocks.removeAt(idx);
        }
      case SimType.buy:
        simC -= log.q! * log.price!;
        final idx = simStocks.indexWhere((s) => s.ticker == log.ticker);
        if (idx >= 0) {
          final s = simStocks[idx];
          final totalVal = s.q * s.price + log.q! * log.price!;
          s.price = totalVal / (s.q + log.q!);
          s.q += log.q!;
          s.cPercent = log.c ?? 0;
          s.imPercent = log.im ?? 100;
        } else {
          simStocks.add(MarginStock(
            ticker: log.ticker!,
            q: log.q!,
            price: log.price!,
            cPercent: log.c ?? 0,
            imPercent: log.im ?? 100,
            al: 0,
          ));
        }
    }
  }

  return (
    simC: simC,
    simStocks: simStocks,
    res: computeMargin(simC, mmRatio, xRatio, simStocks),
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MarginScreenV2 extends StatefulWidget {
  const MarginScreenV2({super.key});

  @override
  State<MarginScreenV2> createState() => _MarginScreenV2State();
}

class _MarginScreenV2State extends State<MarginScreenV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  // Account params
  double _cash = 1000000000;
  double _creditLimit = 0;
  double _mmRatio = 50; // percent
  double _xRatio = 100; // percent

  // Portfolio
  final List<MarginStock> _stocks = [];
  Map<String, Map<String, double>> _paramMap = {}; // ticker → {c, im, al}
  bool _loadingParams = true;

  // Simulation
  final List<SimLog> _logs = [];
  int _logIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadMarginParams();
    _stocks.add(MarginStock());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadMarginParams() async {
    try {
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final resp = await dio.get(ApiConfig.marginParams);
      if (resp.data is Map && resp.data['params'] is List) {
        final map = <String, Map<String, double>>{};
        for (final p in (resp.data['params'] as List)) {
          map[(p['ticker'] as String).toUpperCase()] = {
            'c': (p['c_ratio'] as num).toDouble(),
            'im': (p['im_ratio'] as num).toDouble(),
            'al': (p['al'] as num).toDouble(),
          };
        }
        if (mounted) setState(() { _paramMap = map; _loadingParams = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingParams = false);
    }
  }

  Future<void> _showProfileLoader() async {
    final dio = context.read<InvestmentOpportunitiesRepository>().dio;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _ProfileLoaderSheet(
        dio: dio,
        onSelect: (id) async {
          Navigator.pop(sheetCtx);
          await _applyProfile(id);
        },
      ),
    );
  }

  // id & name được set khi user load 1 profile, dùng để update thay vì tạo mới
  int? _activeProfileId;
  String? _activeProfileName;

  Future<void> _showSaveDialog() async {
    final nameCtrl = TextEditingController(text: _activeProfileName ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Lưu tài khoản', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tên tài khoản (vd: HSC margin)',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.brandPrimaryDark),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimaryDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await _doSave(name);
  }

  Future<void> _doSave(String name) async {
    try {
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final portfolio = _stocks.map((s) => {
        'ticker': s.ticker,
        'q': s.q,
        'q_pending': s.qPending,
        'p': s.price,
        'c_percent': s.cPercent / 100,
        'im_percent': s.imPercent / 100,
        'al': s.al ?? 0,
      }).toList();
      final body = {
        if (_activeProfileId != null) 'id': _activeProfileId,
        'account_name': name,
        'cash_balance': _cash,
        'credit_limit': _creditLimit,
        'mm_ratio': _mmRatio,
        'portfolio_data': portfolio,
      };
      final resp = await dio.post(ApiConfig.marginProfiles, data: body);
      if (!mounted) return;
      setState(() {
        _activeProfileId = resp.data['id'] as int?;
        _activeProfileName = name;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã lưu "$name"'),
        backgroundColor: AppColors.brandPrimaryDark,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
      }
    }
  }

  Future<void> _applyProfile(int id) async {
    try {
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final resp = await dio.get(ApiConfig.marginProfiles, queryParameters: {'id': id});
      if (resp.data is! Map) return;
      final data = resp.data as Map;
      final portfolio = (data['portfolio_data'] as List?) ?? const [];
      final stocks = portfolio.map<MarginStock>((p) {
        final m = p as Map;
        return MarginStock(
          ticker: (m['ticker'] as String? ?? '').toUpperCase(),
          q: (m['q'] as num?)?.toDouble() ?? 0,
          qPending: (m['q_pending'] as num?)?.toDouble() ?? 0,
          price: (m['p'] as num?)?.toDouble() ?? 0,
          cPercent: ((m['c_percent'] as num?)?.toDouble() ?? 0) * 100,
          imPercent: ((m['im_percent'] as num?)?.toDouble() ?? 1) * 100,
          al: (m['al'] as num?)?.toDouble(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _activeProfileId = id;
        _activeProfileName = data['account_name'] as String?;
        _cash = (data['cash_balance'] as num?)?.toDouble() ?? _cash;
        _creditLimit = (data['credit_limit'] as num?)?.toDouble() ?? _creditLimit;
        _mmRatio = (data['mm_ratio'] as num?)?.toDouble() ?? _mmRatio;
        _stocks
          ..clear()
          ..addAll(stocks.isEmpty ? [MarginStock()] : stocks);
      });
      // refresh giá mới nhất cho từng mã
      for (final s in _stocks) {
        if (s.ticker.isNotEmpty) await _fetchTickerInfo(s);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải tài khoản "${data['account_name']}"'),
            backgroundColor: AppColors.brandPrimaryDark,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được tài khoản: $e')),
        );
      }
    }
  }

  Future<void> _fetchTickerInfo(MarginStock stk) async {
    if (stk.ticker.isEmpty) return;
    // First try local param map
    final local = _paramMap[stk.ticker.toUpperCase()];
    if (local != null) {
      stk.cPercent = local['c']!;
      stk.imPercent = local['im']!;
      stk.al = local['al'];
    }
    // Fetch live price
    try {
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final resp = await dio.get(ApiConfig.marginTickerInfo,
          queryParameters: {'ticker': stk.ticker.toUpperCase()});
      if (resp.data is Map) {
        stk.price = (resp.data['price'] as num?)?.toDouble() ?? stk.price;
        stk.cPercent = (resp.data['c_ratio'] as num?)?.toDouble() ?? stk.cPercent;
        stk.imPercent = (resp.data['im_ratio'] as num?)?.toDouble() ?? stk.imPercent;
        stk.al = (resp.data['al'] as num?)?.toDouble() ?? stk.al;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  MarginResult get _t0 => computeMargin(
        _cash, _mmRatio / 100, _xRatio / 100, _stocks);

  ({double simC, List<MarginStock> simStocks, MarginResult res}) get _t1 =>
      applySimulation(_cash, _mmRatio / 100, _xRatio / 100, _stocks, _logs);

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t0 = _t0;
    final t1r = _t1;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: const Text('Chi tiết danh mục',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.brandPrimaryDark,
          labelColor: AppColors.brandPrimaryDark,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Hiện tại (T0)'),
            Tab(text: 'Giả lập (T1)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildT0Tab(t0),
          _buildT1Tab(t1r.res, t1r.simC),
        ],
      ),
    );
  }

  // ─── T0 tab ───────────────────────────────────────────────────────────────

  Widget _buildT0Tab(MarginResult t0) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountCard(
            cash: _cash,
            creditLimit: _creditLimit,
            mmRatio: _mmRatio,
            xRatio: _xRatio,
            profileName: _activeProfileName,
            onEdit: _showAccountDialog,
            onLoad: _showProfileLoader,
            onSave: _showSaveDialog,
          ),
          const SizedBox(height: 12),
          _MrGauge(mr: t0.mr, isCall: t0.isCall),
          const SizedBox(height: 12),
          _SummaryCard(result: t0, label: 'Hiện tại'),
          const SizedBox(height: 16),
          _buildPortfolioSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── T1 tab ───────────────────────────────────────────────────────────────

  Widget _buildT1Tab(MarginResult t1, double simC) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCenter(
            onDeposit: _showDepositDialog,
            onWithdraw: _showWithdrawDialog,
            onBuy: _showBuyDialog,
            onSell: _showSellDialog,
          ),
          const SizedBox(height: 12),
          _MrGauge(mr: t1.mr, isCall: t1.isCall),
          const SizedBox(height: 12),
          _SummaryCard(result: t1, label: 'Dự kiến (T1)', accent: true),
          const SizedBox(height: 16),
          _buildSimLog(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Portfolio ────────────────────────────────────────────────────────────

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Danh mục cổ phiếu',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _stocks.add(MarginStock())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandPrimaryDark.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.brandPrimaryDark, size: 16),
                    const SizedBox(width: 4),
                    Text('Thêm mã', style: TextStyle(color: AppColors.brandPrimaryDark, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._stocks.asMap().entries.map((e) => _StockCard(
              stock: e.value,
              index: e.key,
              onRemove: () => setState(() => _stocks.removeAt(e.key)),
              onFetchInfo: () async => _fetchTickerInfo(e.value),
              onChanged: () => setState(() {}),
            )),
      ],
    );
  }

  // ─── Simulation Log ───────────────────────────────────────────────────────

  Widget _buildSimLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Nhật ký giả lập',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            if (_logs.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _logs.clear()),
                child: const Text('Xóa tất cả',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('Chưa có thao tác giả lập',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          )
        else
          ..._logs.asMap().entries.map((e) => _SimLogItem(
                log: e.value,
                index: e.key,
                onRemove: () => setState(() => _logs.removeWhere((l) => l.id == e.value.id)),
              )),
      ],
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showAccountDialog() {
    double cash = _cash;
    double cl = _creditLimit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountDialog(
        cash: cash,
        creditLimit: cl,
        mmRatio: _mmRatio,
        xRatio: _xRatio,
        onConfirm: (c, cl2, mm, x) => setState(() {
          _cash = c;
          _creditLimit = cl2;
          _mmRatio = mm;
          _xRatio = x;
        }),
      ),
    );
  }

  void _showDepositDialog() {
    _showAmountDialog('Nạp tiền', Colors.green, (amt) {
      setState(() => _logs.add(SimLog(
            id: _logIdCounter++,
            type: SimType.deposit,
            amount: amt,
          )));
    });
  }

  void _showWithdrawDialog() {
    _showAmountDialog('Rút tiền', Colors.redAccent, (amt) {
      setState(() => _logs.add(SimLog(
            id: _logIdCounter++,
            type: SimType.withdraw,
            amount: amt,
          )));
    });
  }

  void _showAmountDialog(String title, Color color, void Function(double) onAdd) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmountDialog(title: title, color: color, onConfirm: onAdd),
    );
  }

  void _showBuyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TradeDialog(
        title: 'Mua cổ phiếu',
        isBuy: true,
        paramMap: _paramMap,
        onConfirm: (ticker, q, p, c, im) {
          setState(() => _logs.add(SimLog(
                id: _logIdCounter++,
                type: SimType.buy,
                ticker: ticker,
                q: q,
                price: p,
                c: c,
                im: im,
              )));
        },
      ),
    );
  }

  void _showSellDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TradeDialog(
        title: 'Bán cổ phiếu',
        isBuy: false,
        paramMap: _paramMap,
        onConfirm: (ticker, q, p, c, im) {
          setState(() => _logs.add(SimLog(
                id: _logIdCounter++,
                type: SimType.sell,
                ticker: ticker,
                q: q,
                price: p,
                c: null,
                im: null,
              )));
        },
      ),
    );
  }
}

// ─── MR Gauge ─────────────────────────────────────────────────────────────────

class _MrGauge extends StatelessWidget {
  final double mr;
  final bool isCall;
  const _MrGauge({required this.mr, required this.isCall});

  @override
  Widget build(BuildContext context) {
    final pct = mr == 9999 ? 200.0 : mr * 100;
    final color = pct >= 150
        ? AppColors.successDark
        : pct >= 120
            ? AppColors.warningDark
            : pct >= 100
                ? Colors.orange
                : AppColors.dangerDark;
    final label = pct >= 150
        ? 'AN TOÀN'
        : pct >= 120
            ? 'BÌNH THƯỜNG'
            : pct >= 100
                ? 'CẢNH BÁO'
                : 'CALL MARGIN';

    final barFill = min(pct / 200.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tỷ lệ ký quỹ (MR)',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    mr == 9999 ? 'N/A' : '${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: color, fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFill,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0%', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('100%', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('150%', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('200%+', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final MarginResult result;
  final String label;
  final bool accent;
  const _SummaryCard({required this.result, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = accent
        ? AppColors.successDark.withValues(alpha: 0.4)
        : Colors.white12;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent
                  ? AppColors.successDark.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(accent ? Icons.fast_forward_rounded : Icons.history_rounded,
                    color: accent ? AppColors.successDark : Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: accent ? AppColors.successDark : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _row('Số dư tiền (C)', result.c,
                    danger: result.c < 0, success: result.c >= 0),
                _row('Giá trị TT (A)', result.a),
                _row('Tài sản ký quỹ (CV)', result.cv),
                if (result.cvPending > 0)
                  _row('Chờ về (CV Pending)', result.cvPending, info: true),
                _divider(),
                _row('Giá trị ký quỹ (E)', result.e, bold: true),
                _row('Yêu cầu KQ (IM)', result.im),
                _row('KQ duy trì (MM)', result.mm),
                _divider(),
                _row('Phần dư EE', result.ee,
                    danger: result.ee < 0, success: result.ee >= 0, bold: true),
                _row('Thặng dư Surplus', result.surplus,
                    danger: result.surplus < 0, success: result.surplus >= 0, bold: true),
                if (result.isCall)
                  _row('Yêu cầu bổ sung (MC)', result.mc, danger: true, bold: true),
                if (result.alTotal > 0)
                  _row('Tổng dư nợ mã (AL)', result.alTotal, danger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value,
      {bool bold = false, bool danger = false, bool success = false, bool info = false}) {
    Color color = Colors.white70;
    if (danger) color = AppColors.dangerDark;
    if (success) color = AppColors.successDark;
    if (info) color = AppColors.brandSecondaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Text(
            _fmt(value),
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white10, height: 12, thickness: 1);
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final double cash, creditLimit, mmRatio, xRatio;
  final String? profileName;
  final VoidCallback onEdit;
  final VoidCallback onLoad;
  final VoidCallback onSave;
  const _AccountCard(
      {required this.cash,
      required this.creditLimit,
      required this.mmRatio,
      required this.xRatio,
      this.profileName,
      required this.onEdit,
      required this.onLoad,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profileName != null) ...[
                  Text(profileName!,
                      style: TextStyle(
                          color: AppColors.brandPrimaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                ],
                _item('Số dư tiền (C)', _fmt(cash),
                    color: cash < 0 ? AppColors.dangerDark : AppColors.successDark),
                const SizedBox(height: 4),
                _item('Hạn mức tín dụng (CL)', _fmt(creditLimit)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _item('mm%', '${mmRatio.toStringAsFixed(0)}%'),
                    const SizedBox(width: 16),
                    _item('X%', '${xRatio.toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.folder_open_outlined,
                    color: AppColors.brandPrimaryDark, size: 22),
                tooltip: 'Tải tài khoản đã lưu',
                onPressed: onLoad,
              ),
              IconButton(
                icon: Icon(Icons.save_outlined,
                    color: AppColors.brandPrimaryDark, size: 22),
                tooltip: 'Lưu tài khoản',
                onPressed: onSave,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                tooltip: 'Sửa thông số',
                onPressed: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value, {Color? color}) => Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ─── Stock Card ───────────────────────────────────────────────────────────────

class _StockCard extends StatefulWidget {
  final MarginStock stock;
  final int index;
  final VoidCallback onRemove;
  final Future<void> Function() onFetchInfo;
  final VoidCallback onChanged;
  const _StockCard(
      {required this.stock,
      required this.index,
      required this.onRemove,
      required this.onFetchInfo,
      required this.onChanged});

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard> {
  late final TextEditingController _ticker =
      TextEditingController(text: widget.stock.ticker);
  late final TextEditingController _q =
      TextEditingController(text: _fmtNum(widget.stock.q));
  late final TextEditingController _qPend =
      TextEditingController(text: _fmtNum(widget.stock.qPending));
  late final TextEditingController _price =
      TextEditingController(text: (widget.stock.price / 1000).toStringAsFixed(2));
  late final TextEditingController _c =
      TextEditingController(text: widget.stock.cPercent.toStringAsFixed(0));
  late final TextEditingController _im =
      TextEditingController(text: widget.stock.imPercent.toStringAsFixed(0));
  late final TextEditingController _al =
      TextEditingController(text: _fmtNum(widget.stock.al ?? 0));

  bool _fetching = false;
  Timer? _debounce;

  void _onTickerChanged(String value) {
    final t = value.trim().toUpperCase();
    _debounce?.cancel();
    if (t.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _ticker.text.trim().toUpperCase() == t) _fetch();
    });
  }

  void _sync() {
    widget.stock.q = _parseNum(_q.text);
    widget.stock.qPending = _parseNum(_qPend.text);
    widget.stock.price = (double.tryParse(_price.text.replaceAll(',', '.')) ?? 0) * 1000;
    widget.stock.cPercent = double.tryParse(_c.text) ?? 0;
    widget.stock.imPercent = double.tryParse(_im.text) ?? 100;
    final alVal = _al.text.trim();
    widget.stock.al = alVal.isEmpty ? null : _parseNum(alVal);
    widget.onChanged();
  }

  Future<void> _fetch() async {
    widget.stock.ticker = _ticker.text.toUpperCase();
    setState(() => _fetching = true);
    await widget.onFetchInfo();
    _price.text = (widget.stock.price / 1000).toStringAsFixed(2);
    _c.text = widget.stock.cPercent.toStringAsFixed(0);
    _im.text = widget.stock.imPercent.toStringAsFixed(0);
    _al.text = _fmtNum(widget.stock.al ?? 0);
    setState(() => _fetching = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ticker.dispose();
    _q.dispose();
    _qPend.dispose();
    _price.dispose();
    _c.dispose();
    _im.dispose();
    _al.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticker row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Input(
                  label: 'Mã CK',
                  controller: _ticker,
                  caps: true,
                  onChanged: _onTickerChanged,
                ),
              ),
              if (_fetching) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Qty row
          Row(
            children: [
              Expanded(child: _Input(label: 'KL sở hữu (q)', controller: _q,
                  onChanged: (_) => _sync())),
              const SizedBox(width: 8),
              Expanded(child: _Input(label: 'KL chờ về', controller: _qPend,
                  onChanged: (_) => _sync())),
            ],
          ),
          const SizedBox(height: 8),
          // Price row
          Row(
            children: [
              Expanded(child: _Input(label: 'Giá (nghìn đ)', controller: _price,
                  decimal: true, onChanged: (_) => _sync())),
              const SizedBox(width: 8),
              Expanded(child: _Input(label: 'Dư nợ mã (AL)', controller: _al,
                  onChanged: (_) => _sync())),
            ],
          ),
          const SizedBox(height: 8),
          // c%/im% row
          Row(
            children: [
              Expanded(child: _Input(label: 'c% (tỷ lệ vay)', controller: _c,
                  decimal: true, onChanged: (_) => _sync())),
              const SizedBox(width: 8),
              Expanded(child: _Input(label: 'im% (ký quỹ)', controller: _im,
                  decimal: true, onChanged: (_) => _sync())),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action Center ────────────────────────────────────────────────────────────

class _ActionCenter extends StatelessWidget {
  final VoidCallback onDeposit, onWithdraw, onBuy, onSell;
  const _ActionCenter(
      {required this.onDeposit,
      required this.onWithdraw,
      required this.onBuy,
      required this.onSell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trung tâm giả lập',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionBtn('Nạp tiền', Icons.add_circle_outline,
                  AppColors.successDark, onDeposit)),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('Rút tiền', Icons.remove_circle_outline,
                  AppColors.dangerDark, onWithdraw)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ActionBtn('Mua CP', Icons.shopping_cart_outlined,
                  AppColors.brandSecondaryDark, onBuy)),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('Bán CP', Icons.sell_outlined,
                  AppColors.warningDark, onSell)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Sim Log Item ─────────────────────────────────────────────────────────────

class _SimLogItem extends StatelessWidget {
  final SimLog log;
  final int index;
  final VoidCallback onRemove;
  const _SimLogItem({required this.log, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;
    switch (log.type) {
      case SimType.deposit:
        color = AppColors.successDark;
        icon = Icons.add_circle_outline;
        text = 'Nạp ${_fmt(log.amount!)}';
      case SimType.withdraw:
        color = AppColors.dangerDark;
        icon = Icons.remove_circle_outline;
        text = 'Rút ${_fmt(log.amount!)}';
      case SimType.buy:
        color = AppColors.brandSecondaryDark;
        icon = Icons.shopping_cart_outlined;
        text = 'Mua ${_fmtNum(log.q!)} ${log.ticker} @ ${(log.price! / 1000).toStringAsFixed(2)}k';
      case SimType.sell:
        color = AppColors.warningDark;
        icon = Icons.sell_outlined;
        text = 'Bán ${_fmtNum(log.q!)} ${log.ticker} @ ${(log.price! / 1000).toStringAsFixed(2)}k';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${index + 1}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Account Dialog ───────────────────────────────────────────────────────────

class _AccountDialog extends StatefulWidget {
  final double cash, creditLimit, mmRatio, xRatio;
  final void Function(double, double, double, double) onConfirm;
  const _AccountDialog(
      {required this.cash,
      required this.creditLimit,
      required this.mmRatio,
      required this.xRatio,
      required this.onConfirm});

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController _cash =
      TextEditingController(text: _fmtNum(widget.cash));
  late final TextEditingController _cl =
      TextEditingController(text: _fmtNum(widget.creditLimit));
  late final TextEditingController _mm =
      TextEditingController(text: widget.mmRatio.toStringAsFixed(0));
  late final TextEditingController _x =
      TextEditingController(text: widget.xRatio.toStringAsFixed(0));

  @override
  void dispose() {
    _cash.dispose();
    _cl.dispose();
    _mm.dispose();
    _x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Thông số tài khoản',
      child: Column(
        children: [
          _Input(label: 'Số dư tiền C (VNĐ)', controller: _cash,
              hint: 'Âm nếu có dư nợ'),
          const SizedBox(height: 10),
          _Input(label: 'Hạn mức tín dụng CL', controller: _cl),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Input(label: 'mm% (duy trì)', controller: _mm, decimal: true)),
              const SizedBox(width: 8),
              Expanded(child: _Input(label: 'X% (call ratio)', controller: _x, decimal: true)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(
                  _parseNum(_cash.text),
                  _parseNum(_cl.text),
                  double.tryParse(_mm.text) ?? 50,
                  double.tryParse(_x.text) ?? 100,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Xác nhận',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Amount Dialog ────────────────────────────────────────────────────────────

class _AmountDialog extends StatefulWidget {
  final String title;
  final Color color;
  final void Function(double) onConfirm;
  const _AmountDialog(
      {required this.title, required this.color, required this.onConfirm});

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: widget.title,
      child: Column(
        children: [
          _Input(label: 'Số tiền (VNĐ)', controller: _ctrl, hint: 'Ví dụ: 50000000'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amt = _parseNum(_ctrl.text);
                if (amt <= 0) return;
                widget.onConfirm(amt);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Xác nhận ${widget.title}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trade Dialog ─────────────────────────────────────────────────────────────

class _TradeDialog extends StatefulWidget {
  final String title;
  final bool isBuy;
  final Map<String, Map<String, double>> paramMap;
  final void Function(String, double, double, double?, double?) onConfirm;
  const _TradeDialog(
      {required this.title,
      required this.isBuy,
      required this.paramMap,
      required this.onConfirm});

  @override
  State<_TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<_TradeDialog> {
  final _ticker = TextEditingController();
  final _q = TextEditingController();
  final _price = TextEditingController();
  final _c = TextEditingController(text: '0');
  final _im = TextEditingController(text: '100');

  @override
  void dispose() {
    _ticker.dispose(); _q.dispose(); _price.dispose();
    _c.dispose(); _im.dispose();
    super.dispose();
  }

  void _onTickerChanged(String t) {
    final p = widget.paramMap[t.toUpperCase()];
    if (p != null) {
      _c.text = p['c']!.toStringAsFixed(0);
      _im.text = p['im']!.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: widget.title,
      child: Column(
        children: [
          _Input(label: 'Mã CK', controller: _ticker, caps: true,
              onChanged: _onTickerChanged),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Input(label: 'Khối lượng', controller: _q)),
              const SizedBox(width: 8),
              Expanded(child: _Input(label: 'Giá (nghìn đ)', controller: _price, decimal: true)),
            ],
          ),
          if (widget.isBuy) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Input(label: 'c%', controller: _c, decimal: true)),
                const SizedBox(width: 8),
                Expanded(child: _Input(label: 'im%', controller: _im, decimal: true)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final t = _ticker.text.trim().toUpperCase();
                final q = _parseNum(_q.text);
                final p = (double.tryParse(_price.text.replaceAll(',', '.')) ?? 0) * 1000;
                if (t.isEmpty || q <= 0 || p <= 0) return;
                widget.onConfirm(
                  t, q, p,
                  widget.isBuy ? double.tryParse(_c.text) : null,
                  widget.isBuy ? double.tryParse(_im.text) : null,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isBuy
                    ? AppColors.brandSecondaryDark
                    : AppColors.warningDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Xác nhận',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sheet wrapper ─────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C2033),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Shared input ─────────────────────────────────────────────────────────────

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool decimal;
  final bool caps;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _Input({
    required this.label,
    required this.controller,
    this.decimal = false,
    this.caps = false,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textCapitalization:
              caps ? TextCapitalization.characters : TextCapitalization.none,
          keyboardType: caps
              ? TextInputType.text
              : decimal
                  ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                  : TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppColors.brandPrimaryDark.withValues(alpha: 0.5)),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final abs = v.abs();
  String formatted;
  if (abs >= 1e9) {
    formatted = '${(abs / 1e9).toStringAsFixed(2)} tỷ';
  } else if (abs >= 1e6) {
    formatted = '${(abs / 1e6).toStringAsFixed(1)} tr';
  } else {
    formatted = abs.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }
  return v < 0 ? '-$formatted' : formatted;
}

String _fmtNum(double v) => v == 0
    ? '0'
    : v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );

double _parseNum(String s) {
  if (s.isEmpty) return 0;
  // Handles both 1.000.000 (VN format) and 1000000
  final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0;
}

// ─── Profile loader bottom sheet ──────────────────────────────────────────────

class _ProfileLoaderSheet extends StatefulWidget {
  final Dio dio;
  final ValueChanged<int> onSelect;
  const _ProfileLoaderSheet({required this.dio, required this.onSelect});

  @override
  State<_ProfileLoaderSheet> createState() => _ProfileLoaderSheetState();
}

class _ProfileLoaderSheetState extends State<_ProfileLoaderSheet> {
  List<Map<String, dynamic>>? _profiles;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await widget.dio.get(ApiConfig.marginProfiles);
      final list = (resp.data['profiles'] as List?) ?? const [];
      if (mounted) {
        setState(() => _profiles = list.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tài khoản đã lưu',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_profiles == null && _err == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_err != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Lỗi tải danh sách: $_err',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              )
            else if (_profiles!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Chưa có tài khoản nào được lưu.\nVui lòng lưu trên web trước.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _profiles!.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (_, i) {
                    final p = _profiles![i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.brandPrimaryDark),
                      title: Text(p['account_name'] as String? ?? 'Không tên',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Tiền: ${_fmt((p['cash_balance'] as num?)?.toDouble() ?? 0)} · ${p['stock_count'] ?? 0} mã',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                      onTap: () => widget.onSelect(p['id'] as int),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
