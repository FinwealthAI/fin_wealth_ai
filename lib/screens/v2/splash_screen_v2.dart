import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/theme.dart';

class SplashScreenV2 extends StatefulWidget {
  const SplashScreenV2({super.key});

  @override
  State<SplashScreenV2> createState() => _SplashScreenV2State();
}

class _SplashScreenV2State extends State<SplashScreenV2> {
  bool _navigated = false;

  void _go(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _go('/v2');
        } else if (state is AuthFailure) {
          _go('/login-v2');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkBg,
                AppColors.brandPrimary.withValues(alpha: 0.25),
                AppColors.darkBg,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      AppColors.brandPrimary,
                      AppColors.brandSecondary,
                    ]),
                    boxShadow: AppShadows.purpleGlow,
                  ),
                  child: const Icon(Icons.bolt,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('FinWealth',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
