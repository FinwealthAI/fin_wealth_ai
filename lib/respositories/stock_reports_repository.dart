import 'package:dio/dio.dart';
import 'package:fin_wealth/models/stock_reports.dart';
import 'package:fin_wealth/config/api_config.dart';

/// Kết quả tóm tắt (trả cả HTML và Markdown để UI tùy chọn render)
class SummaryResult {
  final int id;
  final bool cached;
  final String? summaryHtml;
  final String? summaryMd;

  const SummaryResult({
    required this.id,
    required this.cached,
    this.summaryHtml,
    this.summaryMd,
  });

  factory SummaryResult.fromJson(Map<String, dynamic> json) {
    return SummaryResult(
      id: (json['id'] ?? 0) as int,
      cached: (json['cached'] ?? false) as bool,
      summaryHtml: json['summary_html'] as String?,
      summaryMd: json['summary_md'] as String?,
    );
  }
}

class StockReportsRepository {
  final Dio dio;
  StockReportsRepository(this.dio);


  /// Lấy danh sách báo cáo (có phân trang + filter)
  Future<PagedResult<StockReport>> fetchReports({
    int page = 1,
    String? stock,
    String? sourceId,
  }) async {
    final resp = await dio.get(
      ApiConfig.analysisReports,
      queryParameters: {
        'page': page,
        if (stock != null && stock.isNotEmpty) 'stock': stock,
        if (sourceId != null && sourceId.isNotEmpty && sourceId != 'all') 'source': sourceId,
      },
    );

    if (resp.statusCode == 200) {
      final m = resp.data as Map<String, dynamic>;
      final list = (m['results'] as List? ?? <dynamic>[])
          .map((e) => StockReport.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult<StockReport>(
        items: list,
        page: (m['page'] ?? 1) as int,
        numPages: (m['num_pages'] ?? 1) as int,
        total: (m['total'] ?? list.length) as int,
      );
    }

    if (resp.statusCode == 401) {
      throw Exception('401: Chưa xác thực hoặc token đã hết hạn.');
    }
    throw Exception('Failed to load reports: ${resp.statusCode} - ${resp.data}');
  }

  /// Lấy danh sách nguồn báo cáo (kèm option "Tất cả nguồn")
  Future<List<StockReportSource>> fetchSources() async {
    final resp = await dio.get(ApiConfig.analysisSources);
    if (resp.statusCode == 200) {
      final list = (resp.data as List? ?? <dynamic>[])
          .map((e) => StockReportSource.fromJson(e as Map<String, dynamic>))
          .toList();
      return [StockReportSource(id: 'all', name: 'Nguồn'), ...list];
    }
    if (resp.statusCode == 401) {
      throw Exception('401: Chưa xác thực hoặc token đã hết hạn.');
    }
    throw Exception('Failed to load sources: ${resp.statusCode} - ${resp.data}');
  }

  /// 🔹 Tạo/Lấy tóm tắt cho 1 report (server sẽ cache; lần sau trả nhanh)
  /// Backend: POST /api/analysis-reports/<id>/summary/
  /// Trả về cả HTML và Markdown (nếu server gửi), ưu tiên dùng HTML để render nhanh với flutter_html.
  Future<SummaryResult> getOrCreateSummary(int reportId) async {
    final resp = await dio.post('${ApiConfig.mobileApi}/analysis-reports/$reportId/summary/');

    if (resp.statusCode == 200) {
      return SummaryResult.fromJson(resp.data as Map<String, dynamic>);
    }

    // Các lỗi thường gặp được map thông điệp rõ ràng
    if (resp.statusCode == 400) {
      // ví dụ: "Báo cáo chưa có nội dung để tóm tắt."
      final msg = (resp.data is Map && (resp.data as Map).containsKey('error'))
          ? (resp.data['error'] as String)
          : 'Yêu cầu không hợp lệ (400).';
      throw Exception(msg);
    }
    if (resp.statusCode == 401) {
      throw Exception('401: Chưa xác thực hoặc token đã hết hạn.');
    }
    if (resp.statusCode == 404) {
      throw Exception('Không tìm thấy báo cáo (404).');
    }
    throw Exception('Lỗi tóm tắt ${resp.statusCode}: ${resp.data}');
  }

  /// Tiện ích: lấy trực tiếp HTML (nếu bạn chỉ cần HTML để render).
  Future<String> getSummaryHtml(int reportId) async {
    final res = await getOrCreateSummary(reportId);
    if ((res.summaryHtml ?? '').isNotEmpty) return res.summaryHtml!;
    // fallback sang markdown nếu server không trả html
    if ((res.summaryMd ?? '').isNotEmpty) return res.summaryMd!;
    throw Exception('Không có nội dung tóm tắt.');
  }

  /// Tiện ích: lấy trực tiếp Markdown (nếu muốn render bằng flutter_markdown)
  Future<String> getSummaryMarkdown(int reportId) async {
    final res = await getOrCreateSummary(reportId);
    if ((res.summaryMd ?? '').isNotEmpty) return res.summaryMd!;
    // fallback sang html nếu cần
    if ((res.summaryHtml ?? '').isNotEmpty) return res.summaryHtml!;
    throw Exception('Không có nội dung tóm tắt.');
  }
}
