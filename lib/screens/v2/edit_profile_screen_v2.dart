import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

/// Cập nhật hồ sơ: email + số điện thoại.
/// - Phone lưu thẳng (không xác thực).
/// - Đổi email → bước nhập OTP gửi tới email mới (giống đăng ký).
class EditProfileScreenV2 extends StatefulWidget {
  const EditProfileScreenV2({super.key});

  @override
  State<EditProfileScreenV2> createState() => _EditProfileScreenV2State();
}

class _EditProfileScreenV2State extends State<EditProfileScreenV2> {
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _otp = TextEditingController();

  bool _loading = false;
  bool _otpStep = false;
  String _pendingEmail = '';

  @override
  void initState() {
    super.initState();
    final repo = context.read<AuthRepository>();
    _email = TextEditingController(text: repo.email ?? '');
    _phone = TextEditingController(text: repo.phone ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    if (email.isEmpty) {
      _snack('Vui lòng nhập email');
      return;
    }

    setState(() => _loading = true);
    try {
      final otpRequired = await context
          .read<AuthRepository>()
          .requestProfileUpdate(email: email, phone: phone);
      if (!mounted) return;
      if (otpRequired) {
        setState(() {
          _otpStep = true;
          _pendingEmail = email;
        });
        _snack('Đã gửi mã OTP tới $email', ok: true);
      } else {
        _snack('Cập nhật thành công', ok: true);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otp.text.trim();
    if (otp.length < 4) {
      _snack('Vui lòng nhập mã OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().verifyProfileUpdate(otp);
      if (!mounted) return;
      _snack('Cập nhật email thành công', ok: true);
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthRepository>().resendProfileUpdateOtp();
      _snack('Đã gửi lại mã OTP', ok: true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(title: 'Cập nhật thông tin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _otpStep ? _buildOtpStep() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _email,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            helperText: 'Đổi email sẽ cần xác thực OTP gửi tới email mới.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phone,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FwButton(
          label: 'Lưu thay đổi',
          fullWidth: true,
          size: FwButtonSize.lg,
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nhập mã OTP đã gửi tới $_pendingEmail',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _otp,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 6),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '------',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FwButton(
          label: 'Xác nhận',
          fullWidth: true,
          size: FwButtonSize.lg,
          loading: _loading,
          onPressed: _loading ? null : _verify,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _loading ? null : _resend,
          child: const Text('Gửi lại mã'),
        ),
      ],
    );
  }
}
