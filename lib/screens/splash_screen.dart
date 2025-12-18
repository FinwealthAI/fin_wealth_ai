import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/blocs/auth/auth_bloc.dart';
import 'package:fin_wealth/blocs/auth/auth_state.dart';
import 'package:fin_wealth/screens/home_screen.dart';
import 'package:fin_wealth/screens/log_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHome(Map<String, dynamic> userData) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreenMultiNav(userData: userData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Chờ animation hoàn thành rồi mới chuyển trang
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          
          if (state is AuthSuccess) {
            _navigateToHome(state.userData);
          } else if (state is AuthInitial || state is AuthFailure) {
            _navigateToLogin();
          }
          // AuthLoading -> không làm gì, chờ tiếp
        });
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade900, // Tím đậm ở trên
                Colors.purple.shade800,     // Chuyển sang tím vừa
                Colors.deepPurple.shade900, // Kết thúc vẫn là tím đậm (thay vì trắng)
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stack để xếp chồng Loading bao quanh Logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Loading Indicator bao bên ngoài
                            SizedBox(
                              width: 250, // Lớn hơn logo
                              height: 250,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                            
                            // 2. Logo ở giữa
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
