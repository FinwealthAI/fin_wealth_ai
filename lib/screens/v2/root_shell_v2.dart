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
// import 'reports_screen_v2.dart';
import 'portfolio_list_screen_v2.dart';
import 'screener_screen_v2.dart';
import 'strategy_screen_v2.dart';
import 'watchlist_screen_v2.dart';
import '../../widgets/dashboard/profile_bar.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import 'notifications_screen_v2.dart';
import '../investment_profile_screen.dart';

class RootShellNav {
  static final GlobalKey<RootShellV2State> key =
      GlobalKey<RootShellV2State>();

  /// Về tab Trang chủ của "Phân tích sâu". Đang ở chat thì giữ nguyên chat
  /// (chat mới là trang chủ của app).
  static void goHome() {
    key.currentState?.goHome();
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

/// Mặc định app mở thẳng màn **Chat** (giống `/agent/` trên web). Các tab
/// Trang chủ / Chiến lược / Thị trường / Khác chỉ xuất hiện khi user chọn
/// "Phân tích sâu" trong menu (dấu 3 gạch); nút Mr.Wealth ở giữa thanh tab
/// đưa về lại chat. Cả hai giao diện cùng sống trong một IndexedStack nên
/// chuyển qua lại không làm mất hội thoại đang stream.
class RootShellV2State extends State<RootShellV2> {
  int _index = 0;

  /// false = Chat (mặc định), true = "Phân tích sâu" (bottom nav 4 tab).
  bool _deepMode = false;

  /// Các tab chỉ dựng khi lần đầu vào "Phân tích sâu" — mở app không tải dữ
  /// liệu Home/Strategy/Market vô ích. Dựng rồi thì giữ nguyên (không reload).
  bool _deepBuilt = false;

  late final _tabs = <Widget>[
    HomeScreenV2(onOpenChat: showChat),
    const StrategyScreenV2(),
    const MarketEvaluationScreenV2(),
    const _MoreMenuScreenV2(),
  ];

  /// Mở một tab của "Phân tích sâu" (tự chuyển sang giao diện đó nếu đang ở chat).
  void setIndex(int i) {
    if (!mounted) return;
    setState(() {
      _index = i;
      _deepMode = true;
      _deepBuilt = true;
    });
  }

  void goHome() {
    if (!mounted) return;
    setState(() => _index = 0);
  }

  /// Vào giao diện "Phân tích sâu" (tab đang chọn được giữ nguyên).
  void showDeepAnalysis() {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _deepMode = true;
      _deepBuilt = true;
    });
  }

  /// Về màn Chat (trang chính).
  void showChat() {
    if (!mounted) return;
    setState(() => _deepMode = false);
  }

  /// Menu đóng lại rồi mới đổi giao diện, tránh drawer còn "treo" khi cross-fade.
  void _menuOpenDeepAnalysis(BuildContext drawerContext) {
    Navigator.of(drawerContext).pop();
    showDeepAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Vào thẳng /v2 không qua splash (vd web mở lại URL cũ): chờ
        // CheckAuthStatus resolve rồi mới dựng tab — nếu không, Home sẽ
        // build khi token chưa nạp → chào "Khách" + fetch dashboard bản guest.
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }
        return _buildShell();
      },
    );
  }

  Widget _buildShell() {
    // Back ở "Phân tích sâu" → về chat thay vì thoát app.
    return PopScope(
      canPop: !_deepMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) showChat();
      },
      child: IndexedStack(
        index: _deepMode ? 1 : 0,
        children: [
          ChatScreenV2(
            menuDrawer: _ShellMenuDrawer(
              onDeepAnalysis: _menuOpenDeepAnalysis,
            ),
            onOpenDeepAnalysis: showDeepAnalysis,
          ),
          if (_deepBuilt) _buildDeepScaffold() else const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildDeepScaffold() {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _MrWealthFab(onTap: showChat),
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
            _navItem(0, Icons.home_outlined, Icons.home, 'Trang chủ'),
            _navItem(1, Icons.rocket_launch_outlined, Icons.rocket_launch,
                'Chiến lược'),
            // Khoảng trống cho nút Mr.Wealth nhô lên ở giữa.
            const SizedBox(width: 56),
            _navItem(2, Icons.speed_outlined, Icons.speed, 'Thị trường'),
            _navItem(3, Icons.grid_view_outlined, Icons.grid_view, 'Khác'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final selected = _index == index;
    final color =
        selected ? AppColors.brandPrimaryDark : AppColors.darkTextMuted;
    return Expanded(
      child: InkResponse(
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

/// Menu trái của màn chat (dấu 3 gạch). Cố ý rất ngắn — chỉ lối vào
/// "Phân tích sâu" + vài mục tài khoản; công cụ khác nằm trong "Phân tích sâu".
class _ShellMenuDrawer extends StatelessWidget {
  final void Function(BuildContext drawerContext) onDeepAnalysis;
  const _ShellMenuDrawer({required this.onDeepAnalysis});

  void _push(BuildContext context, Widget w) {
    Navigator.of(context).pop(); // đóng drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  }

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    await context.read<AuthRepository>().logout();
    nav.pushNamedAndRemoveUntil('/login-v2', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final isGuest = authRepo.accessToken == null;
    final username = authRepo.username ?? 'Khách';
    final expiration = authRepo.expirationDate;
    final lowPoints = !isGuest && authRepo.totalPoints < kLowPointsThreshold;
    final text = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.brandPrimary.withValues(alpha: 0.2),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: text.titleMedium
                          ?.copyWith(color: AppColors.brandPrimaryDark),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium),
                        if (!isGuest && expiration != null)
                          Text(
                            'Hết hạn: $expiration',
                            style: text.labelSmall?.copyWith(
                              color: lowPoints
                                  ? AppColors.warningDark
                                  : AppColors.darkTextMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            // Lối vào chính — nổi bật như nút chuyển giao diện trên web.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Material(
                color: AppColors.brandPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => onDeepAnalysis(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.insights,
                            color: AppColors.brandPrimaryDark),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phân tích sâu',
                                  style: text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                'Thị trường, chiến lược, danh mục…',
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.darkTextSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.darkTextMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isGuest) ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Hồ sơ đầu tư'),
                onTap: () => _push(context, const InvestmentProfileScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Thông báo'),
                onTap: () => _push(context, const NotificationsScreenV2()),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Nâng cấp tài khoản'),
                onTap: () => _push(context, const UpgradeScreenV2()),
              ),
            ],
            const Spacer(),
            const Divider(color: AppColors.darkBorder, height: 1),
            if (isGuest)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Đăng nhập'),
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed('/login-v2'),
              )
            else
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () => _logout(context),
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

  /// Khách bấm vào tính năng cần tài khoản → hỏi đăng nhập thay vì mở thẳng
  /// màn hình (màn đó sẽ gọi API không có token và hiện lỗi tải dữ liệu).
  static void _pushOrPromptLogin(BuildContext context, bool isGuest, Widget w) {
    if (!isGuest) {
      _push(context, w);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Đăng nhập',
            style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 16)),
        content: const Text(
          'Vui lòng đăng nhập để sử dụng tính năng này.',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login-v2');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

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
                        onTap: () => _pushOrPromptLogin(
                            context, isGuest, const InvestmentProfileScreen()),
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
                      onTap: () => _pushOrPromptLogin(
                          context, isGuest, const PortfolioListScreenV2()),
                    ),
                    _MenuItem(
                      'Danh sách theo dõi',
                      Icons.bookmark_outline,
                      onTap: () => _pushOrPromptLogin(
                          context, isGuest, const WatchlistScreenV2()),
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
                    const _MenuItem('Về FinWealth', Icons.info_outline),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
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

  const _MenuItem(this.title, this.icon, {this.onTap}) : isDestructive = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
