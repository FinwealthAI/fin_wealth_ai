import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/config/api_config.dart';
import '../theme/theme.dart';
import '../widgets/common/common.dart';

class InvestmentProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const InvestmentProfileScreen({super.key, this.isOnboarding = false});

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
          SnackBar(content: Text('Lỗi tải hồ sơ: $e'), backgroundColor: AppColors.danger),
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
          const SnackBar(content: Text('Đã lưu hồ sơ đầu tư!'), backgroundColor: AppColors.success),
        );
        if (widget.isOnboarding) {
          Navigator.of(context).pushNamedAndRemoveUntil('/v2', (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(
        title: widget.isOnboarding ? 'Thiết lập hồ sơ' : 'Hồ Sơ Đầu Tư',
        subtitle: 'Cá nhân hóa trải nghiệm',
        actions: widget.isOnboarding
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/v2', (route) => false),
                  child: const Text('Bỏ qua',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ]
            : const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandPrimary.withValues(alpha: 0.2),
                          AppColors.brandSecondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: AppColors.brandPrimaryDark, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Khám phá tiềm năng',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.brandPrimaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Giúp chúng tôi hiểu rõ hơn về phong cách đầu tư của bạn để đưa ra khuyến nghị phù hợp nhất.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.darkTextSecondary,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Experience Section
                  _buildSection(
                    icon: Icons.school_outlined,
                    title: 'Kinh nghiệm đầu tư',
                    subtitle: 'Bạn đã đầu tư được bao lâu rồi?',
                    color: const Color(0xFF06B6D4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: experienceChoices.map((choice) {
                        final isSelected = _investorExperience == choice['value'];
                        return _buildChoiceChip(
                          label: choice['label']!,
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _investorExperience = selected ? choice['value'] : null;
                            });
                          },
                          color: const Color(0xFF06B6D4),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Methods Section
                  _buildSection(
                    icon: Icons.auto_graph_outlined,
                    title: 'Phương pháp đầu tư',
                    subtitle: 'Chiến lược bạn thường áp dụng (Có thể chọn nhiều)',
                    color: AppColors.brandPrimaryDark,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: methodChoices.map((choice) {
                        final isSelected = _investmentMethods.contains(choice['value']);
                        return _buildFilterChip(
                          label: choice['label']!,
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
                          color: AppColors.brandPrimaryDark,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Cycle Section
                  _buildSection(
                    icon: Icons.timer_outlined,
                    title: 'Chu kỳ đầu tư',
                    subtitle: 'Thời gian bạn thường nắm giữ cổ phiếu',
                    color: AppColors.successDark,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cycleChoices.map((choice) {
                        final isSelected = _investmentCycles.contains(choice['value']);
                        return _buildFilterChip(
                          label: choice['label']!,
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
                          color: AppColors.successDark,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Risk Section
                  _buildSection(
                    icon: Icons.security_outlined,
                    title: 'Khẩu vị rủi ro',
                    subtitle: 'Mức độ chấp nhận rủi ro hiện tại',
                    color: AppColors.dangerDark,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: riskChoices.map((choice) {
                        final isSelected = _riskTolerance.contains(choice['value']);
                        return _buildFilterChip(
                          label: choice['label']!,
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
                          color: AppColors.dangerDark,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkBg,
            border: Border(top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5))),
          ),
          child: FwButton(
            label: widget.isOnboarding ? 'Bắt đầu đầu tư' : 'Cập nhật hồ sơ',
            icon: widget.isOnboarding ? Icons.arrow_forward : Icons.save_outlined,
            loading: _isSaving,
            fullWidth: true,
            onPressed: _isSaving ? null : _saveProfile,
          ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.2),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.darkTextSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? color : Colors.white.withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.2),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : AppColors.darkTextSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? color : Colors.white.withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
