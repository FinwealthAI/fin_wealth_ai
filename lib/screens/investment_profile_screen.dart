import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/config/api_config.dart';

class InvestmentProfileScreen extends StatefulWidget {
  const InvestmentProfileScreen({super.key});

  @override
  State<InvestmentProfileScreen> createState() => _InvestmentProfileScreenState();
}

class _InvestmentProfileScreenState extends State<InvestmentProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Form data
  String? _investorExperience;
  List<String> _investmentMethods = [];
  List<String> _investmentCycles = [];
  List<String> _riskTolerance = [];

  // Choices from backend
  static const experienceChoices = [
    {'value': 'new', 'label': 'Mới đầu tư'},
    {'value': 'experienced', 'label': 'Nhà đầu tư có kinh nghiệm'},
  ];

  static const methodChoices = [
    {'value': 'growth', 'label': 'Tăng trưởng'},
    {'value': 'value', 'label': 'Giá trị'},
    {'value': 'dividend', 'label': 'Cổ tức'},
    {'value': 'swing', 'label': 'Lướt sóng'},
    {'value': 'accumulation', 'label': 'Tích sản'},
  ];

  static const cycleChoices = [
    {'value': 'short', 'label': 'Ngắn hạn (T+)'},
    {'value': 'medium', 'label': 'Trung hạn (1-6 tháng)'},
    {'value': 'long', 'label': 'Dài hạn (> 1 năm)'},
  ];

  static const riskChoices = [
    {'value': 'low', 'label': 'Thấp'},
    {'value': 'medium', 'label': 'Trung bình'},
    {'value': 'high', 'label': 'Cao'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Accept': 'application/json',
          if (authRepo.accessToken != null)
            'Authorization': 'Bearer ${authRepo.accessToken}',
        },
      ));

      final response = await dio.get('/api/investment-profile/');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _investorExperience = data['investor_experience'];
          _investmentMethods = List<String>.from(data['investment_methods'] ?? []);
          _investmentCycles = List<String>.from(data['investment_cycles'] ?? []);
          _riskTolerance = List<String>.from(data['risk_tolerance'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hồ sơ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
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

      await dio.put('/api/investment-profile/', data: {
        'investor_experience': _investorExperience,
        'investment_methods': _investmentMethods,
        'investment_cycles': _investmentCycles,
        'risk_tolerance': _riskTolerance,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ đầu tư!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Đầu Tư'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ Sơ Đầu Tư Của Bạn',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Giúp chúng tôi hiểu rõ hơn về phong cách đầu tư của bạn để đưa ra khuyến nghị phù hợp nhất.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Experience Section
                  _buildSection(
                    icon: Icons.school,
                    title: 'Kinh nghiệm đầu tư',
                    subtitle: 'Bạn đã đầu tư được bao lâu rồi?',
                    color: const Color(0xFF06B6D4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: experienceChoices.map((choice) {
                        final isSelected = _investorExperience == choice['value'];
                        return ChoiceChip(
                          label: Text(choice['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _investorExperience = selected ? choice['value'] : null;
                            });
                          },
                          selectedColor: const Color(0xFF06B6D4),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Methods Section
                  _buildSection(
                    icon: Icons.show_chart,
                    title: 'Phương pháp đầu tư',
                    subtitle: 'Bạn thường áp dụng chiến lược nào? (Có thể chọn nhiều)',
                    color: const Color(0xFF6366F1),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: methodChoices.map((choice) {
                        final isSelected = _investmentMethods.contains(choice['value']);
                        return FilterChip(
                          label: Text(choice['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _investmentMethods.add(choice['value']!);
                              } else {
                                _investmentMethods.remove(choice['value']);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF6366F1),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cycle Section
                  _buildSection(
                    icon: Icons.access_time,
                    title: 'Chu kỳ đầu tư',
                    subtitle: 'Bạn thường nắm giữ cổ phiếu trong bao lâu?',
                    color: const Color(0xFF10B981),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cycleChoices.map((choice) {
                        final isSelected = _investmentCycles.contains(choice['value']);
                        return FilterChip(
                          label: Text(choice['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _investmentCycles.add(choice['value']!);
                              } else {
                                _investmentCycles.remove(choice['value']);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF10B981),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Risk Section
                  _buildSection(
                    icon: Icons.shield,
                    title: 'Khẩu vị rủi ro',
                    subtitle: 'Mức độ chấp nhận rủi ro của bạn là gì?',
                    color: const Color(0xFFEF4444),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: riskChoices.map((choice) {
                        final isSelected = _riskTolerance.contains(choice['value']);
                        return FilterChip(
                          label: Text(choice['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _riskTolerance.add(choice['value']!);
                              } else {
                                _riskTolerance.remove(choice['value']);
                              }
                            });
                          },
                          selectedColor: const Color(0xFFEF4444),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text('Lưu Hồ Sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
