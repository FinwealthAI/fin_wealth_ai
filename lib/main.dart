import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Repositories
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/respositories/market_repository.dart';
import 'package:fin_wealth/respositories/stock_repository.dart';
import 'package:fin_wealth/respositories/stock_reports_repository.dart';
import 'package:fin_wealth/respositories/investment_opportunities_repository.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';
import 'package:fin_wealth/respositories/blog_repository.dart';
import 'package:fin_wealth/respositories/strategy_repository.dart';
import 'package:fin_wealth/respositories/market_evaluation_repository.dart';

// Blocs
import 'package:fin_wealth/blocs/auth/auth_bloc.dart';
import 'package:fin_wealth/blocs/auth/auth_event.dart';
import 'package:fin_wealth/blocs/auth/auth_state.dart';
import 'package:fin_wealth/blocs/market/market_bloc.dart';
import 'package:fin_wealth/blocs/search/search_bloc.dart';

// Screens
import 'package:fin_wealth/screens/v2/root_shell_v2.dart' show RootShellV2, RootShellNav;
import 'package:fin_wealth/screens/v2/login_screen_v2.dart';
import 'package:fin_wealth/screens/v2/splash_screen_v2.dart';
import 'package:fin_wealth/screens/v2/stock_detail_screen_v2.dart';
import 'package:fin_wealth/screens/v2/upgrade_screen_v2.dart';
import 'package:fin_wealth/config/api_config.dart';
import 'package:fin_wealth/theme/theme.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    try {
      // WebView platform init — wrapped in try-catch to avoid crash on unsupported platforms
    } catch (e) {
      print('WebView initialization error: $e');
    }
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (s) => s != null && s < 500,
  ));

  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    responseHeader: false,
    responseBody: false,
  ));

  runApp(MyApp(dio: dio, navigatorKey: navigatorKey));
}

class MyApp extends StatefulWidget {
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.dio, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastExpiredCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExpiryOnResume();
    }
  }

  Future<void> _checkExpiryOnResume() async {
    // Cooldown 5 phút để tránh spam khi user switch app liên tục
    final now = DateTime.now();
    if (_lastExpiredCheck != null &&
        now.difference(_lastExpiredCheck!).inMinutes < 5) return;
    _lastExpiredCheck = now;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final authBloc = ctx.read<AuthBloc>();
    if (authBloc.state is! AuthSuccess) return;

    authBloc.add(CheckAccountExpiry());

    // Lắng nghe state thay đổi ngay sau khi dispatch event
    final stream = authBloc.stream;
    await for (final s in stream.timeout(const Duration(seconds: 10),
        onTimeout: (sink) => sink.close())) {
      if (!mounted) return;
      if (s is AuthAccountExpired) {
        final navCtx = widget.navigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          authBloc.add(LogoutRequested());
          widget.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => const UpgradeScreenV2(fromExpiredSession: true)),
            (_) => false,
          );
        }
        return;
      }
      if (s is! AuthSuccess) return; // state khác → stop
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(dio: widget.dio)),
        RepositoryProvider(create: (_) => MarketRepository(dio: widget.dio)),
        RepositoryProvider(create: (_) => StockRepository(dio: widget.dio)),
        RepositoryProvider(create: (_) => StockReportsRepository(widget.dio)),
        RepositoryProvider(create: (_) => InvestmentOpportunitiesRepository(widget.dio)),
        RepositoryProvider(create: (_) => SearchStockRepository(widget.dio)),
        RepositoryProvider(create: (_) => WatchlistRepository(dio: widget.dio)),
        RepositoryProvider(create: (_) => BlogRepository(widget.dio)),
        RepositoryProvider(create: (_) => StrategyRepository(dio: widget.dio)),
        RepositoryProvider(create: (_) => MarketEvaluationRepository(dio: widget.dio)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => AuthBloc(authRepository: ctx.read<AuthRepository>())..add(CheckAuthStatus())),
          BlocProvider(create: (ctx) => SearchBloc(stockRepository: ctx.read<StockRepository>())),
          BlocProvider(create: (ctx) => MarketBloc(marketRepository: ctx.read<MarketRepository>())),
        ],
        child: MaterialApp(
          navigatorKey: widget.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'FinWealth',
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          initialRoute: '/splash-v2',
          routes: {
            '/splash-v2': (_) => const SplashScreenV2(),
            '/login-v2': (_) => const LoginScreenV2(),
            '/v2': (_) => RootShellV2(key: RootShellNav.key),
            '/stock-detail-v2': (ctx) => StockDetailScreenV2(
                  ticker: ModalRoute.of(ctx)!.settings.arguments as String? ?? 'VNM',
                ),
          },
        ),
      ),
    );
  }
}
