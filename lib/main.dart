import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Repositories
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/respositories/market_repository.dart';
import 'package:fin_wealth/respositories/stock_repository.dart';
import 'package:fin_wealth/respositories/stock_reports_repository.dart'; // ✅ THÊM IMPORT NÀY
import 'package:fin_wealth/respositories/investment_opportunities_repository.dart'; 
import 'package:fin_wealth/respositories/search_stock_repository.dart'; 
import 'package:fin_wealth/respositories/watchlist_repository.dart'; 

// Blocs
import 'package:fin_wealth/blocs/auth/auth_bloc.dart';
import 'package:fin_wealth/blocs/auth/auth_event.dart';
import 'package:fin_wealth/blocs/market/market_bloc.dart';
import 'package:fin_wealth/blocs/search/search_bloc.dart';

// Screens
import 'package:fin_wealth/screens/log_in_screen.dart';
import 'package:fin_wealth/config/api_config.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Không cần khởi tạo InAppWebViewPlatform thủ công trên desktop
  // Flutter và plugin sẽ tự chọn platform khả dụng nếu được hỗ trợ.
  // 1) Tạo 1 Dio dùng chung toàn app
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    // để 401 không ném exception, cho Bloc/repo tự xử lý
    validateStatus: (s) => s != null && s < 500,
  ));

  // Log request + header để dễ debug Authorization
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    responseHeader: false,
    responseBody: false,
  ));

  runApp(MyApp(dio: dio));
} // ✅ Đóng hàm main

class MyApp extends StatelessWidget {
  final Dio dio;
  const MyApp({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(dio: dio)),          // ✅ thêm dòng này
        RepositoryProvider(create: (_) => MarketRepository(dio: dio)),
        RepositoryProvider(create: (_) => StockRepository(dio: dio)),
        RepositoryProvider(create: (_) => StockReportsRepository(dio)),       // dùng chung dio
        RepositoryProvider(create: (_) => InvestmentOpportunitiesRepository(dio)),
        RepositoryProvider(create: (_) => SearchStockRepository(dio)),
        RepositoryProvider(create: (_) => WatchlistRepository(dio: dio)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => AuthBloc(authRepository: ctx.read<AuthRepository>())..add(CheckAuthStatus())),
          BlocProvider(create: (ctx) => SearchBloc(stockRepository: ctx.read<StockRepository>())),
          BlocProvider(create: (ctx) => MarketBloc(marketRepository: ctx.read<MarketRepository>())),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (_) => LoginScreen(),
          },
        ),
      ),
    );
  }
}
