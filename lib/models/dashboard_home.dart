import '../respositories/investment_opportunities_repository.dart'
    show DailySummaryData;
import 'watchlist_item.dart';

double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '').trim());
  return null;
}

int _toI(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

/// Một item WealthScore đã được enrich với boost/preset/giá.
/// Tương ứng `WealthScoreItemSerializer` ở backend.
class WealthScoreItem {
  final String ticker;
  final double fundamentalScore;
  final double technicalScore;
  final double score;
  final String? strengthLabel;
  final double? boostScore;
  final List<String> matchedPresetNames;
  final double? close;
  final double? changePct;

  WealthScoreItem({
    required this.ticker,
    required this.fundamentalScore,
    required this.technicalScore,
    required this.score,
    this.strengthLabel,
    this.boostScore,
    this.matchedPresetNames = const [],
    this.close,
    this.changePct,
  });

  factory WealthScoreItem.fromJson(Map<String, dynamic> j) => WealthScoreItem(
        ticker: (j['ticker'] ?? '').toString(),
        fundamentalScore: _toD(j['fundamental_score']) ?? 0,
        technicalScore: _toD(j['technical_score']) ?? 0,
        score: _toD(j['score']) ?? 0,
        strengthLabel: j['strength_label'] as String?,
        boostScore: _toD(j['boost_score']),
        matchedPresetNames:
            (j['matched_preset_names'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        close: _toD(j['close']),
        changePct: _toD(j['change_pct']),
      );
}

class OpenPosition {
  final String ticker;
  final String entryDate;
  final double? entryPrice;
  final double? currentPrice;
  final double? unrealizedPct;
  final int? presetId;
  final String? presetName;
  final String? presetIcon;
  final String? presetColor;
  final double? stopLoss;
  final double? takeProfit;
  final double? winRate;
  final double? profitFactor;
  final double? maxDrawdown;
  final String status;

  OpenPosition({
    required this.ticker,
    required this.entryDate,
    this.entryPrice,
    this.currentPrice,
    this.unrealizedPct,
    this.presetId,
    this.presetName,
    this.presetIcon,
    this.presetColor,
    this.stopLoss,
    this.takeProfit,
    this.winRate,
    this.profitFactor,
    this.maxDrawdown,
    required this.status,
  });

  factory OpenPosition.fromJson(Map<String, dynamic> j) => OpenPosition(
        ticker: (j['ticker'] ?? '').toString(),
        entryDate: (j['entry_date'] ?? '').toString(),
        entryPrice: _toD(j['entry_price']),
        currentPrice: _toD(j['current_price']),
        unrealizedPct: _toD(j['unrealized_pct']),
        presetId: j['preset_id'] is num ? (j['preset_id'] as num).toInt() : null,
        presetName: j['preset_name'] as String?,
        presetIcon: j['preset_icon'] as String?,
        presetColor: j['preset_color'] as String?,
        stopLoss: _toD(j['stop_loss']),
        takeProfit: _toD(j['take_profit']),
        winRate: _toD(j['win_rate']),
        profitFactor: _toD(j['profit_factor']),
        maxDrawdown: _toD(j['max_drawdown']),
        status: (j['status'] ?? '').toString(),
      );
}

class SuggestedStrategy {
  final int id;
  final String name;
  final String? description;
  final int followerCount;
  final double? yearlyReturn;
  final double avgRating;
  final String? authorName;
  final bool authorIsAi;
  final String? authorAvatar;

  SuggestedStrategy({
    required this.id,
    required this.name,
    this.description,
    required this.followerCount,
    this.yearlyReturn,
    required this.avgRating,
    this.authorName,
    required this.authorIsAi,
    this.authorAvatar,
  });

  factory SuggestedStrategy.fromJson(Map<String, dynamic> j) => SuggestedStrategy(
        id: _toI(j['id']),
        name: (j['name'] ?? '').toString(),
        description: j['description'] as String?,
        followerCount: _toI(j['follower_count']),
        yearlyReturn: _toD(j['yearly_return']),
        avgRating: _toD(j['avg_rating']) ?? 5.0,
        authorName: j['author_name'] as String?,
        authorIsAi: j['author_is_ai'] == true,
        authorAvatar: j['author_avatar'] as String?,
      );
}

class LatestReport {
  final int id;
  final String? title;
  final String? date;
  final String? source;
  final String? presignedUrl;
  final List<String> tickers;

  LatestReport({
    required this.id,
    this.title,
    this.date,
    this.source,
    this.presignedUrl,
    this.tickers = const [],
  });

  factory LatestReport.fromJson(Map<String, dynamic> j) => LatestReport(
        id: _toI(j['id']),
        title: j['name'] as String?,
        date: j['date'] as String?,
        source: j['source'] as String?,
        presignedUrl: j['presigned_url'] as String?,
        tickers: (j['tickers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class LatestBlog {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? coverImage;
  final String? publishedAt;
  final int viewsCount;
  final String url;

  LatestBlog({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.coverImage,
    this.publishedAt,
    required this.viewsCount,
    required this.url,
  });

  factory LatestBlog.fromJson(Map<String, dynamic> j) => LatestBlog(
        id: _toI(j['id']),
        title: (j['title'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        excerpt: j['excerpt'] as String?,
        coverImage: j['cover_image'] as String?,
        publishedAt: j['published_at'] as String?,
        viewsCount: _toI(j['views_count']),
        url: (j['url'] ?? '').toString(),
      );
}

/// Toàn bộ payload từ `/mobile/api/dashboard-home/`.
class DashboardHome {
  final DailySummaryData? dailySummary;
  final bool isGuest;
  final int totalPoints;
  final List<int> shortSignalIds;
  final List<int> longSignalIds;

  final List<WealthScoreItem> wsGolden;
  final List<WealthScoreItem> wsRising;
  final List<WealthScoreItem> wsWave;
  final List<WealthScoreItem> wsValue;
  final int wsGoldenCount;
  final int wsRisingCount;
  final int wsWaveCount;
  final int wsValueCount;

  final List<WatchlistItem> watchlist;
  final List<OpenPosition> openPositions;
  final int openCount;
  final bool hasFollowedStrategies;
  final List<SuggestedStrategy> suggestedStrategies;

  final List<LatestBlog> latestBlogs;
  final List<LatestBlog> popularBlogs;
  final List<LatestReport> latestReports;
  final String? dailyBlogUrl;
  final LatestBlog? dailyBlogPost;

  final Map<String, dynamic>? aiTopPick;

  DashboardHome({
    this.dailySummary,
    required this.isGuest,
    this.totalPoints = 0,
    this.shortSignalIds = const [],
    this.longSignalIds = const [],
    this.wsGolden = const [],
    this.wsRising = const [],
    this.wsWave = const [],
    this.wsValue = const [],
    this.wsGoldenCount = 0,
    this.wsRisingCount = 0,
    this.wsWaveCount = 0,
    this.wsValueCount = 0,
    this.watchlist = const [],
    this.openPositions = const [],
    this.openCount = 0,
    this.hasFollowedStrategies = false,
    this.suggestedStrategies = const [],
    this.latestBlogs = const [],
    this.popularBlogs = const [],
    this.latestReports = const [],
    this.dailyBlogUrl,
    this.dailyBlogPost,
    this.aiTopPick,
  });

  factory DashboardHome.fromJson(Map<String, dynamic> data) {
    DailySummaryData? summary;
    final ds = data['daily_summary'];
    if (ds is Map) {
      final flat = <String, dynamic>{};
      flat.addAll(Map<String, dynamic>.from(ds));
      // Bê thêm homepage_charts vào DailySummaryData để render strategy_cards.
      if (data['homepage_charts'] != null) {
        flat['homepage_charts'] = data['homepage_charts'];
      }
      try {
        summary = DailySummaryData.fromJson(flat);
      } catch (_) {
        summary = null;
      }
    }

    List<WealthScoreItem> ws(String k) =>
        ((data[k] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => WealthScoreItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    List<LatestBlog> blogs(String k) =>
        ((data[k] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => LatestBlog.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    return DashboardHome(
      dailySummary: summary,
      isGuest: data['is_guest'] == true,
      totalPoints: _toI(data['total_points']),
      shortSignalIds:
          ((data['short_signal_ids'] as List?) ?? const []).map((e) => _toI(e)).toList(),
      longSignalIds:
          ((data['long_signal_ids'] as List?) ?? const []).map((e) => _toI(e)).toList(),
      wsGolden: ws('ws_golden'),
      wsRising: ws('ws_rising'),
      wsWave: ws('ws_wave'),
      wsValue: ws('ws_value'),
      wsGoldenCount: _toI(data['ws_golden_count']),
      wsRisingCount: _toI(data['ws_rising_count']),
      wsWaveCount: _toI(data['ws_wave_count']),
      wsValueCount: _toI(data['ws_value_count']),
      watchlist: ((data['watchlist'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            // Backend trả close/change_pct → map sang current_price/change_percent
            return WatchlistItem(
              id: _toI(m['id']),
              ticker: (m['ticker'] ?? '').toString(),
              companyName: m['company_name'] as String?,
              currentPrice: _toD(m['close']),
              changePercent: _toD(m['change_pct']),
              faTier: m['fa_tier'] as String?,
              taTier: m['ta_tier'] as String?,
              strengthLabel: m['strength_label'] as String?,
            );
          })
          .toList(),
      openPositions: ((data['open_positions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => OpenPosition.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      openCount: _toI(data['open_count']),
      hasFollowedStrategies: data['has_followed_strategies'] == true,
      suggestedStrategies:
          ((data['suggested_strategies'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => SuggestedStrategy.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      latestBlogs: blogs('latest_blogs'),
      popularBlogs: blogs('popular_blogs'),
      latestReports: ((data['latest_reports'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => LatestReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      dailyBlogUrl: data['daily_blog_url'] as String?,
      dailyBlogPost: data['daily_blog_post'] is Map
          ? LatestBlog.fromJson(Map<String, dynamic>.from(data['daily_blog_post'] as Map))
          : null,
      aiTopPick: data['ai_top_pick'] is Map
          ? Map<String, dynamic>.from(data['ai_top_pick'] as Map)
          : null,
    );
  }
}
