import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/screens/strategy_detail_screen.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/config/api_config.dart';

class StrategyCard extends StatefulWidget {
  final StrategyCardData data;
  final double width;
  final double? height;

  const StrategyCard({
    Key? key,
    required this.data,
    this.width = 300,
    this.height,
  }) : super(key: key);

  @override
  State<StrategyCard> createState() => _StrategyCardState();
}

class _StrategyCardState extends State<StrategyCard> {
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.data.isFollowing;
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (authRepo.accessToken != null)
            'Authorization': 'Bearer ${authRepo.accessToken}',
        },
      ));

      final response = await dio.post(
        ApiConfig.toggleFollow,
        data: {
          'model_name': 'strategy',
          'object_id': widget.data.presetId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _isFollowing = data['is_following'] ?? !_isFollowing;
        });
        
        // Hiển thị thông báo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? (_isFollowing ? 'Đã theo dõi' : 'Đã bỏ theo dõi')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra, vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.data.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.data.tickerCount} mã cổ phiếu',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Nút Theo dõi
              GestureDetector(
                onTap: _isLoading ? null : _toggleFollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isFollowing
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFollowing ? Icons.check : Icons.add,
                              size: 14,
                              color: _isFollowing
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isFollowing ? "Đang theo dõi" : "Theo dõi",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isFollowing
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Content Area
          _buildTickerGrid(),
          
          const SizedBox(height: 12),
          
          // Description
          if (widget.data.description != null && widget.data.description!.isNotEmpty)
            Text(
              widget.data.description!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
          const SizedBox(height: 12),
          
          // Actions
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StrategyDetailScreen(
                      title: widget.data.title,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                "Xem chi tiết",
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickerGrid() {
    final tickers = widget.data.data.map((e) {
      if (e is Map) {
        return e['ticker']?.toString() ?? e['label']?.toString() ?? '';
      }
      return '';
    }).where((t) => t.isNotEmpty).toList();

    if (tickers.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    final displayTickers = tickers.take(8).toList();
    final remainingCount = tickers.length - displayTickers.length;

    // Color palette for ticker chips
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple 
      Color(0xFF06B6D4), // Cyan
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFFEC4899), // Pink
      Color(0xFF3B82F6), // Blue
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTickers.asMap().entries.map((entry) {
          final idx = entry.key;
          final ticker = entry.value;
          final color = colors[idx % colors.length];
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Text(
              ticker,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.9),
              ),
            ),
          );
        }),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9CA3AF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF9CA3AF).withOpacity(0.3)),
            ),
            child: Text(
              '+$remainingCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
      ],
    );
  }
}
