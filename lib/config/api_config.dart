/// API Configuration
/// 
/// Manages base URLs for different environments.
/// Use relative paths when web app is deployed on same server as backend
/// to avoid CORS issues.

class ApiConfig {
  // Set to true when deploying to production (same server)
  // Set to false for local development
  static const bool useRelativePaths = true;
  
  static const String websiteUrl = 'https://finwealth.vn';
  
  // Base URL for API calls
  static String get baseUrl => useRelativePaths 
      ? '' // Relative path - same origin, no CORS
      : 'https://finwealth.vn'; // Absolute URL for development
  
  // Specific endpoints
  static String get mobileApi => '$baseUrl/mobile/api';
  static String get api => '$baseUrl/api';
  static String get watchlist => '$baseUrl/watchlist';
  
  // Full endpoint paths
  static String get unlockWealth => '$mobileApi/unlock-wealth/';
  static String get dailyMarketSummary => '$mobileApi/daily-market-summary/';
  static String get userNews => '$mobileApi/user-news/';
  static String get analysisReports => '$mobileApi/analysis-reports/';
  static String get analysisSources => '$mobileApi/analysis-sources/';
  static String get marketReports => '$mobileApi/market-reports/';
  static String get stockReports => '$api/stock-reports';
  static String get latestSignals => '$api/latest-signals/';
  static String get signup => '$api/signup/';
  static String get googleLogin => '$api/google-login/';
  static String get token => '$mobileApi/token/';
  static String get tokenRefresh => '$mobileApi/token/refresh/';
  
  // Watchlist endpoints
  static String get watchlistGetContent => '$watchlist/get-content/';
  static String get watchlistAdd => '$watchlist/add/';
  static String watchlistRemove(int id) => '$watchlist/remove/$id/';

}
