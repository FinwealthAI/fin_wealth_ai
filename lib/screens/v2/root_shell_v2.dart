import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../respositories/auth_repository.dart';
import 'upgrade_screen_v2.dart';
import '../../config/api_config.dart' show kLowPointsThreshold;
import '../../theme/theme.dart';
import 'blog_screen_v2.dart';
import 'chat_screen_v2.dart';
import 'home_screen_v2.dart';
import 'economic_charts_screen_v2.dart';
import 'margin_screen_v2.dart';
import 'market_evaluation_screen_v2.dart';
import 'profile_screen_v2.dart';
// import 'reports_screen_v2.dart';
import 'portfolio_list_screen_v2.dart';
import 'screener_screen_v2.dart';
import 'strategy_screen_v2.dart';
import 'watchlist_screen_v2.dart';
import '../../widgets/dashboard/profile_bar.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import '../../widgets/onboarding/onboarding.dart';
import '../../services/onboarding_prefs.dart';
import 'notifications_screen_v2.dart';
import '../investment_profile_screen.dart';

class RootShellNav {
  static final GlobalKey<RootShellV2State> key =
      GlobalKey<RootShellV2State>();

  static void goHome() {
    key.currentState?.setIndex(0);
  }

  static void goMore() {
    key.currentState?.setIndex(3);
  }

  static void goStrategy() {
    key.currentState?.setIndex(1);
  }

  static void goMarket() {
    key.currentState?.setIndex(2);
  }
}

class RootShellV2 extends StatefulWidget {
  const RootShellV2({super.key});

  @override
  State<RootShellV2> createState() => RootShellV2State();
}

class RootShellV2State extends State<RootShellV2> {
  int _index = 0;

  // GlobalKeys cho tour hướng dẫn cấp app (bottom nav + FAB).
  final GlobalKey _kHome = GlobalKey();
  final GlobalKey _kStrategy = GlobalKey();
  final GlobalKey _kMarket = GlobalKey();
  final GlobalKey _kMore = GlobalKey();
  final GlobalKey _kFab = GlobalKey();
  bool _appTourStarted = false;

  late final _tabs = <Widget>[
    HomeScreenV2(onOpenChat: _openChat),
    const StrategyScreenV2(),
    const MarketEvaluationScreenV2(),
    const _MoreMenuScreenV2(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAppTour());
  }

  /// Tour giới thiệu các khu vực chính của app (bottom nav + Mr.Wealth FAB),
  /// chạy 1 lần đầu cho user đã đăng nhập (cờ local `app`). Tour chat chi tiết
  /// nằm riêng trong ChatScreenV2.
  Future<void> _maybeShowAppTour() async {
    if (_appTourStarted || !mounted) return;
    final authRepo = context.read<AuthRepository>();
    if (authRepo.accessToken == null) return; // khách → bỏ qua
    final username = authRepo.username ?? '';
    if (await OnboardingPrefs.hasSeenApp(username)) return;
    if (!mounted) return;
    _appTourStarted = true;

    final start = await showAppWelcomeDialog(context);
    if (!mounted) return;
    if (!start) {
      await OnboardingPrefs.markAppSeen(username);
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final steps = <CoachStep>[
      CoachStep(_kHome, '🏠 Trang chủ',
          'Tổng quan thị trường, cổ phiếu nổi bật & cơ hội đáng chú ý trong ngày — nơi bạn bắt đầu mỗi phiên.'),
      CoachStep(_kStrategy, '🚀 Chiến lược',
          'Bộ lọc cổ phiếu theo phương pháp (CANSLIM, VCP…) và sàn chiến lược mẫu để tìm mã phù hợp.'),
      CoachStep(_kMarket, '📊 Thị trường',
          'Đánh giá sức khỏe thị trường: điểm số ngắn/dài hạn, mức độ thận trọng — biết "nhiệt độ" trước khi vào lệnh.'),
      CoachStep(_kMore, '🔲 Khác',
          'Quản lý danh mục, danh sách theo dõi, lọc cổ phiếu, tính margin, blog, biểu đồ kinh tế & hồ sơ đầu tư.'),
      CoachStep(_kFab, '🤖 Mr.Wealth — Trợ lý AI',
          'Trái tim của Finwealth: chạm để hỏi phân tích cổ phiếu, đánh giá danh mục, tìm cơ hội. Mở được từ mọi nơi trong app.',
          circle: true),
    ];

    runCoachMarks(context, steps,
        onDone: () => OnboardingPrefs.markAppSeen(username));
  }

  void setIndex(int i) {
    if (!mounted) return;
    setState(() => _index = i);
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreenV2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: KeyedSubtree(
        key: _kFab,
        child: _MrWealthFab(onTap: _openChat),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _navItem(0, Icons.home_outlined, Icons.home, 'Trang chủ',
                itemKey: _kHome),
            _navItem(1, Icons.rocket_launch_outlined, Icons.rocket_launch,
                'Chiến lược', itemKey: _kStrategy),
            // Khoảng trống cho nút Mr.Wealth nhô lên ở giữa.
            const SizedBox(width: 56),
            _navItem(2, Icons.speed_outlined, Icons.speed, 'Thị trường',
                itemKey: _kMarket),
            _navItem(3, Icons.grid_view_outlined, Icons.grid_view, 'Khác',
                itemKey: _kMore),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label,
      {Key? itemKey}) {
    final selected = _index == index;
    final color =
        selected ? AppColors.brandPrimaryDark : AppColors.darkTextMuted;
    return Expanded(
      child: InkResponse(
        key: itemKey,
        onTap: () => setState(() => _index = index),
        radius: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
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
                    lowPointsWarning: !isGuest && totalPoints < kLowPointsThreshold,
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
                      'Quản lý danh mục',
                      Icons.account_balance_wallet_outlined,
                      onTap: () =>
                          _push(context, const PortfolioListScreenV2()),
                    ),
                    _MenuItem(
                      'Danh sách theo dõi',
                      Icons.bookmark_outline,
                      onTap: () => _push(context, const WatchlistScreenV2()),
                    ),
                    _MenuItem(
                      'Blog',
                      Icons.menu_book_outlined,
                      onTap: () => _push(context, const BlogScreenV2()),
                    ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
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
