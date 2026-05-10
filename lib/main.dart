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

class MyApp extends StatelessWidget {
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.dio, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(dio: dio)),
        RepositoryProvider(create: (_) => MarketRepository(dio: dio)),
        RepositoryProvider(create: (_) => StockRepository(dio: dio)),
        RepositoryProvider(create: (_) => StockReportsRepository(dio)),
        RepositoryProvider(create: (_) => InvestmentOpportunitiesRepository(dio)),
        RepositoryProvider(create: (_) => SearchStockRepository(dio)),
        RepositoryProvider(create: (_) => WatchlistRepository(dio: dio)),
        RepositoryProvider(create: (_) => BlogRepository(dio)),
        RepositoryProvider(create: (_) => StrategyRepository(dio: dio)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => AuthBloc(authRepository: ctx.read<AuthRepository>())..add(CheckAuthStatus())),
          BlocProvider(create: (ctx) => SearchBloc(stockRepository: ctx.read<StockRepository>())),
          BlocProvider(create: (ctx) => MarketBloc(marketRepository: ctx.read<MarketRepository>())),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
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
