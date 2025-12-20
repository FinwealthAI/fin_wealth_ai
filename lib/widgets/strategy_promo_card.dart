import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/screens/strategy_detail_screen.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/config/api_config.dart';

class StrategyPromoCard extends StatefulWidget {
  final StrategyCardData data;
  final double width;

  const StrategyPromoCard({
    Key? key,
    required this.data,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<StrategyPromoCard> createState() => _StrategyPromoCardState();
}

class _StrategyPromoCardState extends State<StrategyPromoCard> {
  late bool _isFollowing;
  late int _followerCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.data.isFollowing;
    _followerCount = widget.data.followerCount;
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
          if (_isFollowing) {
            _followerCount++;
          } else {
            _followerCount = (_followerCount > 0) ? _followerCount - 1 : 0;
          }
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isFollowing ? 'Đã theo dõi' : 'Đã bỏ theo dõi'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error follow: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _viewResults() {
      // Navigate to detail similar to StrategyCard
      // Assuming detail screen needs title + preloadedData (even if empty initially?)
      // Actually StrategyDetailScreen usually does its own fetch or uses passed data.
      // Promo card might not have full 'data' (tickers) initially depending on API.
      // But we pass what we have.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrategyDetailScreen(
            title: widget.data.title,
            preloadedData: widget.data.data,
            presetId: widget.data.presetId,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very light grey bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Followers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Icon placeholder or specific icon
               Container(
                 width: 40, height: 40,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: Colors.grey.withOpacity(0.2)),
                 ),
                 child: Icon(Icons.show_chart, color: Theme.of(context).primaryColor),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       widget.data.title,
                       style: const TextStyle(
                         fontSize: 16, fontWeight: FontWeight.bold,
                         color: Color(0xFF4C1D95), // Deep purple like image
                       ),
                     ),
                   ],
                 ),
               ),
               // Follower count
               Row(
                 children: [
                   const Icon(Icons.people, size: 16, color: Colors.grey),
                   const SizedBox(width: 4),
                   Text(
                     '$_followerCount', 
                     style: const TextStyle(
                       fontWeight: FontWeight.bold, color: Colors.grey
                     ),
                   ),
                 ],
               )
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            widget.data.description ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Author
          Row(
             children: [
               const CircleAvatar(
                 radius: 10,
                 backgroundImage: AssetImage('assets/images/mr_wealth_avatar.png'), // Placeholder
                 backgroundColor: Colors.grey,
               ),
               const SizedBox(width: 6),
               Text(
                 widget.data.author ?? 'Mr.Wealth',
                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
               ),
             ],
          ),
          
          const SizedBox(height: 12),
          
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
               if (widget.data.riskLevel != null)
                 _buildTag(widget.data.riskLevel!, const Color(0xFFFEF3C7), const Color(0xFFD97706)), // Yellow
               if (widget.data.investPeriod != null)
                 _buildTag(widget.data.investPeriod!, const Color(0xFFDBEAFE), const Color(0xFF2563EB)), // Blue
               // Other tags from targetInvestor
               ...widget.data.targetInvestor.map((t) => _buildTag(t, const Color(0xFFE0E7FF), const Color(0xFF4F46E5))),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            children: [
              // Theo doi button (Expand)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleFollow,
                  icon: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_isFollowing ? Icons.check : Icons.add_circle_outline, size: 18),
                  label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED), // Violet
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // View Results button
              ElevatedButton(
                onPressed: _viewResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2), // Light violet
                  foregroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: const Row(
                  children: [
                     Text('Xem kết quả'),
                     SizedBox(width: 4),
                     Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
