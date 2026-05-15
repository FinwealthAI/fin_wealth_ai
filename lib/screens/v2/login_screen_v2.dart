import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/common/platform_google_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'forgot_password_screen_v2.dart';
import 'signup_screen_v2.dart';

class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({super.key});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _showPw = false;

  void _submit() {
    final u = _email.text.trim();
    final p = _pw.text;
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }
    context.read<AuthBloc>().add(LoginEvent(u, p));
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacementNamed('/v2');
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreenV2()),
    );
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreenV2()),
    );
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(GoogleLoginEvent(authEntry: 'login'));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Navigator.of(context).pushReplacementNamed('/v2');
            } else if (state is AuthAccountExpired) {
              showAccountExpiredSheet(context, state);
            } else if (state is AuthFailure &&
                state.error != 'Not logged in') {
              String msg = state.error.replaceFirst('Exception: ', '');
              if (msg.startsWith('DioException') || msg.contains('SocketException')) {
                msg = 'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              AppColors.brandPrimary,
                              AppColors.brandSecondary,
                            ]),
                            boxShadow: AppShadows.purpleGlow,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_standard.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('FinWealth', style: text.displayMedium),
                        const SizedBox(height: 4),
                        Text('Cố vấn đầu tư AI cho người Việt',
                            style: text.bodyMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.xxl),
                        TextField(
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Tên đăng nhập hoặc email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _pw,
                          enabled: !loading,
                          obscureText: !_showPw,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPw
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _showPw = !_showPw),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loading ? null : _forgotPassword,
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FwButton(
                          label: 'Đăng nhập',
                          fullWidth: true,
                          size: FwButtonSize.lg,
                          loading: loading,
                          onPressed: loading ? null : _submit,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FwButton(
                          label: 'Vào với tư cách khách',
                          variant: FwButtonVariant.ghost,
                          fullWidth: true,
                          onPressed: loading ? null : _continueAsGuest,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(children: [
                          Expanded(
                              child: Divider(color: AppColors.darkBorder)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('hoặc', style: text.labelSmall),
                          ),
                          Expanded(
                              child: Divider(color: AppColors.darkBorder)),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        if (kIsWeb)
                          getWebGoogleButton()
                        else
                          FwButton(
                            label: 'Tiếp tục với Google',
                            icon: Icons.g_mobiledata,
                            variant: FwButtonVariant.secondary,
                            fullWidth: true,
                            onPressed: loading ? null : _handleGoogleSignIn,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Chưa có tài khoản? ', style: text.bodySmall),
                            TextButton(
                              onPressed: loading ? null : _goToSignUp,
                              child: const Text('Đăng ký'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
