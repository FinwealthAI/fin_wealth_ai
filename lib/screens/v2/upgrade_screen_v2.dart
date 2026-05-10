import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../respositories/auth_repository.dart';

class UpgradeScreenV2 extends StatelessWidget {
  /// Khi từ splash (tài khoản expired), cần nút đăng xuất để quay về login
  final bool fromExpiredSession;
  const UpgradeScreenV2({super.key, this.fromExpiredSession = false});

  static const _zaloGroup = 'https://zalo.me/g/bqeltx653';
  static const _adminPhone = '0768583768';

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthRepository>().logout();
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login-v2', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final upgradeUrl = authRepo.upgradeUrl ??
        '${ApiConfig.websiteUrl}/open-account/hsc/?u=${authRepo.username ?? ''}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B21E8), Color(0xFF9B3FF8), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Close / Logout button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => fromExpiredSession
                        ? _logout(context)
                        : Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        fromExpiredSession ? Icons.logout : Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo_standard.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Headline
                const Text(
                  'Kích hoạt sức mạnh AI\nNâng tầm đầu tư của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Để tiếp tục sử dụng hệ thống tín hiệu AI và các báo cáo độc quyền, hãy nâng cấp tài khoản của bạn ngay hôm nay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Feature cards row
                Row(
                  children: [
                    _FeatureCard(
                      emoji: '⚡',
                      label: 'Tín hiệu AI Real-time không giới hạn',
                    ),
                    const SizedBox(width: 12),
                    _FeatureCard(
                      emoji: '📊',
                      label: 'Báo cáo phân tích doanh nghiệp chuyên sâu',
                    ),
                    const SizedBox(width: 12),
                    _FeatureCard(
                      emoji: '🎧',
                      label: 'Hỗ trợ 1:1 từ chuyên gia HSC',
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // CTA button
                GestureDetector(
                  onTap: () => _launch(upgradeUrl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'MỞ TÀI KHOẢN HSC NGAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Footer links
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _FooterLink(
                      icon: Icons.phone_outlined,
                      label: 'Hotline: $_adminPhone',
                      onTap: () => _launch('tel:$_adminPhone'),
                    ),
                    _FooterLink(
                      icon: Icons.chat_bubble_outline,
                      label: 'Zalo: Trợ lý FinWealth',
                      onTap: () =>
                          _launch('https://zalo.me/$_adminPhone'),
                    ),
                    _FooterLink(
                      icon: Icons.people_outline,
                      label: 'Cộng đồng Zalo',
                      onTap: () => _launch(_zaloGroup),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeatureCard({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FooterLink(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
