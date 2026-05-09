import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class ChangePasswordScreenV2 extends StatefulWidget {
  const ChangePasswordScreenV2({super.key});

  @override
  State<ChangePasswordScreenV2> createState() => _ChangePasswordScreenV2State();
}

class _ChangePasswordScreenV2State extends State<ChangePasswordScreenV2> {
  final _oldPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _oldPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final old = _oldPw.text.trim();
    final nw = _newPw.text.trim();
    final cf = _confirmPw.text.trim();

    if (old.isEmpty || nw.isEmpty || cf.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (nw != cf) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }
    if (nw.length < 8) {
      _showError('Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().changePassword(
            oldPassword: old,
            newPassword: nw,
            confirmPassword: cf,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
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
    return Scaffold(
      appBar: const FwAppBar(title: 'Đổi mật khẩu'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            _PwField(
              controller: _oldPw,
              label: 'Mật khẩu hiện tại',
              show: _showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.md),
            _PwField(
              controller: _newPw,
              label: 'Mật khẩu mới',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.md),
            _PwField(
              controller: _confirmPw,
              label: 'Xác nhận mật khẩu mới',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              enabled: !_loading,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FwButton(
              label: 'Cập nhật mật khẩu',
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

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const _PwField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.enabled,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !show,
      enabled: enabled,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
