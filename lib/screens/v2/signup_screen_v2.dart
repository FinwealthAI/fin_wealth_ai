import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../investment_profile_screen.dart';

class SignupScreenV2 extends StatefulWidget {
  const SignupScreenV2({super.key});

  @override
  State<SignupScreenV2> createState() => _SignupScreenV2State();
}

class _SignupScreenV2State extends State<SignupScreenV2> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _loading = false;
  bool _showPw = false;
  bool _showConfirmPw = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _pw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_firstName.text.isEmpty ||
        _lastName.text.isEmpty ||
        _email.text.isEmpty ||
        _pw.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin (Họ, Tên, Email, Mật khẩu)');
      return;
    }

    if (_pw.text != _confirmPw.text) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _loading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final success = await authRepo.signUp(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        phone: _phone.text,
        password: _pw.text,
        confirmPassword: _confirmPw.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const InvestmentProfileScreen(isOnboarding: true),
          ),
          (route) => false,
        );
      } else {
        _showError('Đăng ký thất bại. Vui lòng thử lại.');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst('Exception: ', '');
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      backgroundColor: const Color(0xFF0F111A), // Main dark background
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
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
                    'Đăng Ký',
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC084FC),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lastName,
                          decoration: const InputDecoration(
                            labelText: 'Họ',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _firstName,
                          decoration: const InputDecoration(
                            labelText: 'Tên',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _pw,
                    obscureText: !_showPw,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPw = !_showPw),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _confirmPw,
                    obscureText: !_showConfirmPw,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPw ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FwButton(
                    label: 'Đăng Ký',
                    fullWidth: true,
                    size: FwButtonSize.lg,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('HOẶC', style: text.labelSmall?.copyWith(color: Colors.white38)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('G', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Text('Tiếp tục với Google', style: text.titleMedium?.copyWith(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Đã có tài khoản? Đăng nhập ngay',
                      style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
