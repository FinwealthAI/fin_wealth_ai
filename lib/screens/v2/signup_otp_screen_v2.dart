import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../investment_profile_screen.dart';

/// Bước 2 đăng ký: nhập mã OTP đã gửi tới email để hoàn tất tạo tài khoản.
/// Đồng nhất với luồng xác thực email của web.
class SignupOtpScreenV2 extends StatefulWidget {
  final String email;
  const SignupOtpScreenV2({super.key, required this.email});

  @override
  State<SignupOtpScreenV2> createState() => _SignupOtpScreenV2State();
}

class _SignupOtpScreenV2State extends State<SignupOtpScreenV2> {
  final _otp = TextEditingController();
  bool _loading = false;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length < 4) {
      _showError('Vui lòng nhập mã OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.verifySignupOtp(email: widget.email, otp: code);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const InvestmentProfileScreen(isOnboarding: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    try {
      final authRepo = context.read<AuthRepository>();
      final cooldown = await authRepo.resendSignupOtp(widget.email);
      _startCooldown(cooldown);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại mã OTP')),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('Xác thực email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nhập mã OTP',
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC084FC),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Mã xác thực đã được gửi tới ${widget.email}',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FwButton(
                    label: 'Xác nhận',
                    fullWidth: true,
                    size: FwButtonSize.lg,
                    loading: _loading,
                    onPressed: _loading ? null : _verify,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _cooldown > 0 ? null : _resend,
                    child: Text(
                      _cooldown > 0
                          ? 'Gửi lại mã sau ${_cooldown}s'
                          : 'Gửi lại mã OTP',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
