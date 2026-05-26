import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../respositories/auth_repository.dart';

class UpgradeScreenV2 extends StatelessWidget {
  /// Khi từ splash (tài khoản expired), cần nút đăng xuất để quay về login
  final bool fromExpiredSession;
  const UpgradeScreenV2({super.key, this.fromExpiredSession = false});

  static const _hscRegisterUrl = 'https://register.hsc.com.vn/?cid=0013910134';
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
    const upgradeUrl = _hscRegisterUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827).withValues(alpha: 0.7) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textMain = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF374151);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final featureText = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569);

    final checkIcon = const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16);
    final starIcon = const Icon(Icons.star, color: Color(0xFF818CF8), size: 16);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      fromExpiredSession ? Icons.logout : Icons.close,
                      color: titleColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                'Cấu Trúc Gói Dịch Vụ',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Khai thác toàn bộ sức mạnh trí tuệ nhân tạo và kinh nghiệm chuyên gia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Gói 1: Trải nghiệm
              _PricingCard(
                cardBg: cardBg,
                cardBorder: cardBorder,
                badgeText: 'Dành cho người mới',
                badgeColor: textMuted,
                title: 'Trải nghiệm',
                duration: '07 Ngày',
                condition: 'Điều kiện: Mới đăng ký',
                features: const [
                  'Chiến lược đầu tư AI',
                  'Bộ lọc cổ phiếu thông minh',
                  'AI phân tích doanh nghiệp đa chiều',
                  'AI Chatbot 24/7',
                  'Tổng hợp tin tức & insight thị trường',
                  'Định giá & cảnh báo rủi ro bằng AI',
                ],
                icon: checkIcon,
                titleColor: titleColor,
                featureText: featureText,
                textMuted: textMuted,
                buttonText: 'Mở tài khoản',
                isVip: false,
                onPressed: () => _launch(upgradeUrl),
              ),
              const SizedBox(height: 20),

              // Gói 2: Đồng Hành
              _PricingCard(
                cardBg: cardBg,
                cardBorder: cardBorder,
                badgeText: 'Nhà đầu tư mới',
                badgeColor: textMuted,
                title: 'Đồng Hành',
                duration: '30 Ngày',
                condition: 'Đã hoàn tất mở tài khoản HSC thành công',
                features: const [
                  'Chiến lược đầu tư AI',
                  'Bộ lọc cổ phiếu thông minh',
                  'AI phân tích doanh nghiệp đa chiều',
                  'AI Chatbot 24/7',
                  'Tổng hợp tin tức & insight thị trường',
                  'Định giá & cảnh báo rủi ro bằng AI',
                ],
                icon: checkIcon,
                titleColor: titleColor,
                featureText: featureText,
                textMuted: textMuted,
                buttonText: 'Giao dịch ngay',
                isVip: false,
                onPressed: () => _launch(upgradeUrl),
              ),
              const SizedBox(height: 20),

              // Gói 3: Đặc Quyền (VIP)
              _PricingCard(
                cardBg: cardBg,
                cardBorder: const Color(0xFF6366F1),
                badgeText: 'Phổ biến',
                badgeColor: const Color(0xFFA855F7),
                title: 'Đặc Quyền',
                duration: 'Không giới hạn',
                condition: 'NAV >= 50.000.000 VNĐ & Có giao dịch',
                features: const [
                  'Toàn bộ tính năng trên FinWealth',
                  'Hỗ trợ chuyên gia HSC 1:1',
                  'Xây dựng chiến lược cá nhân hóa',
                  'Trải nghiệm sớm mô hình AI mới',
                  'Tư vấn danh mục cá nhân hóa',
                ],
                iconList: [
                  checkIcon,
                  starIcon,
                  starIcon,
                  starIcon,
                  starIcon,
                ],
                titleColor: titleColor,
                featureText: featureText,
                textMuted: textMuted,
                buttonText: 'Duy trì VIP',
                isVip: true,
                onPressed: () => _launch(upgradeUrl),
              ),
              const SizedBox(height: 32),

              // Bottom CTA Section
              Text(
                'Bạn muốn nâng cấp hoặc mở tài khoản ngay?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _launch(upgradeUrl),
                icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white),
                label: const Text('Mở tài khoản ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launch(_zaloGroup),
                icon: Icon(Icons.people, color: titleColor),
                label: Text('Tham gia Cộng đồng Zalo', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cardBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ContactLink(
                    icon: Icons.phone,
                    label: 'Hotline: $_adminPhone',
                    color: textMuted,
                    onTap: () => _launch('tel:$_adminPhone'),
                  ),
                  const SizedBox(width: 24),
                  _ContactLink(
                    icon: Icons.message,
                    label: 'Zalo hỗ trợ',
                    color: textMuted,
                    onTap: () => _launch('https://zalo.me/$_adminPhone'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Color cardBg;
  final Color cardBorder;
  final String badgeText;
  final Color badgeColor;
  final String title;
  final String duration;
  final String condition;
  final List<String> features;
  final Widget? icon;
  final List<Widget>? iconList;
  final Color titleColor;
  final Color featureText;
  final Color textMuted;
  final String buttonText;
  final bool isVip;
  final VoidCallback onPressed;

  const _PricingCard({
    required this.cardBg,
    required this.cardBorder,
    required this.badgeText,
    required this.badgeColor,
    required this.title,
    required this.duration,
    required this.condition,
    required this.features,
    this.icon,
    this.iconList,
    required this.titleColor,
    required this.featureText,
    required this.textMuted,
    required this.buttonText,
    required this.isVip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: isVip ? 2.0 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isVip 
                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isVip ? 16 : 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            badgeText.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            duration,
            style: const TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            condition,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: titleColor.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(features.length, (index) {
              final itemIcon = iconList != null ? iconList![index] : icon!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    itemIcon,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        features[index],
                        style: TextStyle(
                          color: featureText,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isVip
                ? ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: titleColor.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContactLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

