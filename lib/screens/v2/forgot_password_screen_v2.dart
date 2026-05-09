import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class ForgotPasswordScreenV2 extends StatefulWidget {
  const ForgotPasswordScreenV2({super.key});

  @override
  State<ForgotPasswordScreenV2> createState() => _ForgotPasswordScreenV2State();
}

class _ForgotPasswordScreenV2State extends State<ForgotPasswordScreenV2> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _emailCtrl.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email hoặc tên đăng nhập'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await context.read<AuthRepository>().forgotPassword(input);
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const FwAppBar(title: 'Quên mật khẩu'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _sent ? _SuccessView(onBack: () => Navigator.of(context).pop()) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nhập email hoặc tên đăng nhập của bạn. Chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu qua email.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _emailCtrl,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Email hoặc tên đăng nhập',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FwButton(
              label: 'Gửi hướng dẫn',
              fullWidth: true,
              size: FwButtonSize.lg,
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 72, color: Colors.green),
          const SizedBox(height: AppSpacing.lg),
          Text('Đã gửi!', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Kiểm tra hộp thư và làm theo hướng dẫn trong email để đặt lại mật khẩu.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FwButton(
            label: 'Quay lại đăng nhập',
            variant: FwButtonVariant.ghost,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
