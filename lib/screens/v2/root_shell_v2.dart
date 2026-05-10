import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../respositories/auth_repository.dart';
import 'upgrade_screen_v2.dart';
import '../../theme/theme.dart';
import 'ai_toolbox_screen_v2.dart';
import 'blog_screen_v2.dart';
import 'chat_screen_v2.dart';
import 'home_screen_v2.dart';
import 'economic_charts_screen_v2.dart';
import 'margin_screen_v2.dart';
import 'profile_screen_v2.dart';
import 'reports_screen_v2.dart';
import 'screener_screen_v2.dart';
import 'strategy_screen_v2.dart';
import '../../widgets/dashboard/profile_bar.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import 'notifications_screen_v2.dart';
import '../investment_profile_screen.dart';

class RootShellNav {
  static final GlobalKey<RootShellV2State> key =
      GlobalKey<RootShellV2State>();

  static void goHome() {
    key.currentState?.setIndex(0);
  }

  static void goMore() {
    key.currentState?.setIndex(4);
  }

  static void goStrategy() {
    key.currentState?.setIndex(1);
  }
}

class RootShellV2 extends StatefulWidget {
  const RootShellV2({super.key});

  @override
  State<RootShellV2> createState() => RootShellV2State();
}

class RootShellV2State extends State<RootShellV2> {
  int _index = 0;

  late final _tabs = <Widget>[
    HomeScreenV2(onOpenChat: _openChat),
    const StrategyScreenV2(),
    const BlogScreenV2(),
    const ReportsScreenV2(),
    const _MoreMenuScreenV2(),
  ];

  void setIndex(int i) {
    if (!mounted) return;
    setState(() => _index = i);
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreenV2()),
    );
  }

  void _openToolbox() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiToolboxScreenV2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _MrWealthFab(onTap: _openToolbox),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.brandPrimaryDark),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon:
                Icon(Icons.trending_up, color: AppColors.brandPrimaryDark),
            label: 'Chiến lược',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon:
                Icon(Icons.menu_book, color: AppColors.brandPrimaryDark),
            label: 'Blog',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon:
                Icon(Icons.description, color: AppColors.brandPrimaryDark),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon:
                Icon(Icons.grid_view, color: AppColors.brandPrimaryDark),
            label: 'Khác',
          ),
        ],
      ),
    );
  }
}

class _MoreMenuScreenV2 extends StatelessWidget {
  const _MoreMenuScreenV2();

  static void _push(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthRepository>().logout();
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login-v2', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final userData =
            state is AuthSuccess ? state.userData : <String, dynamic>{};
        final authRepo = context.read<AuthRepository>();
        final username = authRepo.username ?? 'Khách';
        final avatarUrl = authRepo.avatar;
        final isGuest = authRepo.accessToken == null;
        final totalPoints = authRepo.totalPoints;
        final expirationDate = authRepo.expirationDate;

        return Scaffold(
          backgroundColor: const Color(0xFF0F111A),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ProfileBar(
                    userName: username,
                    avatarUrl: avatarUrl,
                    daysLeft: isGuest ? null : totalPoints,
                    expirationDate: isGuest ? null : expirationDate,
                    lowPointsWarning: !isGuest && totalPoints < 30,
                    onUpgradeTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const UpgradeScreenV2()),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        Icons.person_outline,
                        'Hồ sơ',
                        onTap: () =>
                            _push(context, const InvestmentProfileScreen()),
                      ),
                      if (!isGuest)
                        _QuickAction(
                          Icons.logout,
                          'Đăng xuất',
                          onTap: () => _logout(context),
                        )
                      else
                        _QuickAction(
                          Icons.login,
                          'Đăng nhập',
                          onTap: () => Navigator.of(context)
                              .pushReplacementNamed('/login-v2'),
                        ),
                      _QuickAction(
                        Icons.notifications_outlined,
                        'Thông báo',
                        onTap: () =>
                            _push(context, const NotificationsScreenV2()),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MenuItem(
                      'Lọc cổ phiếu',
                      Icons.tune_outlined,
                      onTap: () => _push(context, const ScreenerScreenV2()),
                    ),
                    _MenuItem(
                      'Tính margin',
                      Icons.calculate_outlined,
                      onTap: () => _push(context, const MarginScreenV2()),
                    ),
                    _MenuItem(
                      'Biểu đồ kinh tế',
                      Icons.bar_chart_rounded,
                      onTap: () =>
                          _push(context, const EconomicChartsScreenV2()),
                    ),
                    _MenuItem('Về FinWealth', Icons.info_outline),
                    const SizedBox(height: 16),
                    _ServerStatus(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServerStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Kết nối máy chủ ổn định',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickAction(this.icon, this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _MenuItem(this.title, this.icon, {this.isDestructive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6366F1)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _MrWealthFab extends StatelessWidget {
  final VoidCallback onTap;
  const _MrWealthFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFE91E8C),
              Color(0xFF9C27B0),
              Color(0xFF3F51B5),
              Color(0xFF00BCD4),
              Color(0xFF4CAF50),
              Color(0xFFFF6B35),
            ],
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0D0F17),
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Image.asset(
              'assets/images/mr_wealth_avatar.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
