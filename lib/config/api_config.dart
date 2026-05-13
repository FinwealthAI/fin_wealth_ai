/// API Configuration
/// 
/// Manages base URLs for different environments.
/// Use relative paths when web app is deployed on same server as backend
/// to avoid CORS issues.

import 'package:flutter/foundation.dart';

/// Ngưỡng điểm cảnh báo sắp hết hạn — phải khớp với LOW_POINTS_THRESHOLD backend (bot_user/views.py)
const int kLowPointsThreshold = 30;

class ApiConfig {
  // Set to true when deploying to production (same server)
  // Set to false for local development
  static const bool useRelativePaths = bool.fromEnvironment('USE_RELATIVE_PATHS', defaultValue: false);

  // Toggle this to use local backend instead of production
  // Default to true for development, but will be false in production builds
  static const bool useLocalBackend = bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: !kReleaseMode);

  // Google OAuth Client ID
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '280830107479-5b7cim5c869sca8krkqn9pfv35phg1ns.apps.googleusercontent.com',
  );
  
  static const String _productionUrl = 'https://finwealth.vn';
  static String get _localUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  
  static String get websiteUrl => useLocalBackend ? _localUrl : _productionUrl;
  static String get blogUrl => '$websiteUrl/blog/';
  
  // Base URL for API calls
  static String get baseUrl {
    if (useLocalBackend) return _localUrl;
    return useRelativePaths ? '' : _productionUrl;
  }
  
  // Specific endpoints
  static String get mobileApi => '$baseUrl/mobile/api';
  static String get api => '$baseUrl/api';
  static String get watchlist => '$baseUrl/watchlist';
  
  // Full endpoint paths
  static String get dashboardHome => '$mobileApi/dashboard-home/';
  // Alias cũ — sẽ xoá sau khi tất cả màn hình migrate sang dashboardHome
  static String get unlockWealth => '$mobileApi/unlock-wealth/';

  static String get userNews => '$mobileApi/user-news/';
  static String get analysisReports => '$mobileApi/analysis-reports/';
  static String get analysisSources => '$mobileApi/analysis-sources/';
  static String get marketReports => '$mobileApi/market-reports/';
  static String get stockReports => '$api/stock-reports';
  static String get latestSignals => '$api/latest-signals/';
  static String get signup => '$api/signup/';
  static String get googleLogin => '$api/google-login/';
  static String get changePassword => '$api/change-password/';
  static String get forgotPassword => '$api/forgot-password/';
  static String get token => '$mobileApi/token/';
  static String get tokenRefresh => '$mobileApi/token/refresh/';
  
  // Watchlist endpoints
  static String get watchlistGetContent => '$watchlist/get-content/';
  static String get watchlistGet => '$watchlist/api/get/';
  static String get watchlistAdd => '$watchlist/add/';
  static String watchlistRemove(int id) => '$watchlist/remove/$id/';
  
  // Strategy follow endpoint
  static String get toggleFollow => '$baseUrl/api/toggle-follow/';
  
  // Marketplace results endpoint
  static String get marketplaceResults => '$baseUrl/filter-stock/api/v1/marketplace/results/';

  // Strategy detail / review APIs
  static String strategyDetail(int id) => '$baseUrl/filter-stock/api/v1/strategy/$id/detail/';
  static String strategyStats(int id) => '$baseUrl/filter-stock/api/v1/strategy/$id/stats/';
  static String strategyReview(int id) => '$baseUrl/filter-stock/api/v1/strategy/$id/review/';

  // AI Report endpoints
  static String runWorkflow(String ticker) => '$api/run-workflow/$ticker/';
  static String checkTask(String taskId) => '$api/check-task/$taskId/';
  static String get financialAnalysis => '$api/financial-analysis/';
  // Investment profile
  static String get investmentProfile => '$baseUrl/api/investment-profile/';

  // Blog (native JSON API)
  static String get blogList => '$mobileApi/blog/';
  static String blogDetail(String slug) => '$mobileApi/blog/$slug/';

  // Economic charts
  static String get chartsList => '$mobileApi/charts/';
  static String chartData(int id) => '$mobileApi/charts/$id/';

  // Account status — đồng nhất check hết hạn với web
  static String get accountStatus => '$mobileApi/account-status/';

  // Stock screener (custom filter builder)
  static String get screenerFields => '$mobileApi/screener/fields/';
  static String get screenerRun => '$mobileApi/screener/run/';

  // Margin calculator
  static String get marginParams => '$mobileApi/margin/params/';
  static String get marginTickerInfo => '$mobileApi/margin/ticker-info/';
  static String get marginProfiles => '$mobileApi/margin/profiles/';

  // Value chain + economic charts
  static String valueChain(String ticker) => '$mobileApi/value-chain/$ticker/';
}
