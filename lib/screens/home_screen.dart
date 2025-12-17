// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_screen.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:fin_wealth/blocs/auth/auth_bloc.dart';
import 'package:fin_wealth/blocs/auth/auth_state.dart';

// Screens
import 'main_screen.dart';
import 'stock_reports_screen.dart';
import 'chat_screen.dart';
import 'search_stock_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
import 'report_viewer_screen.dart';
import 'investment_profile_screen.dart';

class HomeScreenMultiNav extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreenMultiNav({super.key, required this.userData});

  @override
  State<HomeScreenMultiNav> createState() => _HomeScreenMultiNavState();
}

class _HomeScreenMultiNavState extends State<HomeScreenMultiNav> {
  int _currentIndex = 0;
  String? _chatInitialMessage;

  // Navigator keys cho từng tab
  final _opportunitiesNavKey = GlobalKey<NavigatorState>();
  final _reportsNavKey = GlobalKey<NavigatorState>();
  final _stocksNavKey = GlobalKey<NavigatorState>();
  final _watchlistNavKey = GlobalKey<NavigatorState>();
  final _chatNavKey = GlobalKey<NavigatorState>();

  List<GlobalKey<NavigatorState>> get _navKeys => [
        _opportunitiesNavKey,
        _stocksNavKey,
        _chatNavKey,
        _reportsNavKey,
      ];

  NavigatorState get _currentNavigator => _navKeys[_currentIndex].currentState!;

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  Future<bool> _onWillPop() async {
    final canPop = _currentNavigator.canPop();
    if (canPop) {
      _currentNavigator.pop();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  void _openProfile() {
    Navigator.of(context).pop(); // đóng Drawer trước
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userData: widget.userData),
        settings: const RouteSettings(name: 'profile'),
      ),
    );
  }

  /// Khi người dùng search trên AppBar
  void _handleSearchSubmit(String query) {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return;

    setState(() => _currentIndex = 1); // sang tab Stocks (index 1)

    // Đẩy SearchStockScreen mới trong navigator riêng của tab Stocks
    _stocksNavKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SearchStockScreen(ticker: q)),
      (route) => false,
    );
  }

  void _handleAskAI(String ticker) {
    setState(() {
      _chatInitialMessage = ticker;
      _currentIndex = 2; // Switch to Chat tab (index 2)
    });
    
    // Reset message after a short delay to allow re-triggering for same ticker if needed
    // But for now, let's keep it simple.
  }

  void _logout(BuildContext context) {
    // Implement your logout logic here, e.g., clearing user session, navigating to the login screen, etc.
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Example: Navigate to login screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        child: Scaffold(
        appBar: _SearchAppBar(
          onSubmit: _handleSearchSubmit,
          title: 'FinWealth',
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.9),
                  theme.colorScheme.secondary.withOpacity(0.8),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.onPrimary,
                        backgroundImage: NetworkImage(
                          widget.userData['avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.userData['username'] ?? 'Guest User',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.list_alt, color: theme.colorScheme.primary),
                        title: Text(
                          'Theo dõi',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const WatchlistScreen(),
                              settings: const RouteSettings(name: 'watchlist'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.assessment, color: theme.colorScheme.primary),
                        title: Text(
                          'Hồ sơ đầu tư',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const InvestmentProfileScreen(),
                              settings: const RouteSettings(name: 'investment_profile'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.person, color: theme.colorScheme.primary),
                        title: Text(
                          'Profile',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: _openProfile,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
            ],
            ),
          ),
        ),

        // IndexedStack giữ trạng thái từng tab
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(
              navKey: _opportunitiesNavKey,
              builder: (_) => MainScreen(onAskAI: _handleAskAI),
            ),
            _buildTabNavigator(
              navKey: _stocksNavKey,
              builder: (_) => SearchStockScreen(ticker: 'FPT'),
            ),
            _buildTabNavigator(
              navKey: _chatNavKey,
              builder: (_) => ChatScreen(
                userData: widget.userData,
                initialMessage: _chatInitialMessage,
              ), 
            ),
            _buildTabNavigator(
              navKey: _reportsNavKey,
              builder: (_) => const StockReportsScreen(),
            ),
          ],
        ),


        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.9),
                theme.colorScheme.secondaryContainer.withOpacity(0.7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: theme.colorScheme.onPrimary,
            unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.7),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined, size: 22),
                activeIcon: Icon(Icons.dashboard, size: 22),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded, size: 22),
                activeIcon: Icon(Icons.search, size: 22),
                label: 'Cổ phiếu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 22),
                activeIcon: Icon(Icons.chat_bubble_rounded, size: 22),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined, size: 22),
                activeIcon: Icon(Icons.description, size: 22),
                label: 'Báo cáo',
              ),
            ],
          ),
        ),

        ),
      ),
    );
  }

  Widget _buildTabNavigator({
    required GlobalKey<NavigatorState> navKey,
    required WidgetBuilder builder,
  }) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: builder,
        settings: const RouteSettings(name: 'root'),
      ),
    );
  }
}

/// ----------------------
/// 🔍 AppBar có SearchBar chung
/// ----------------------


class _SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSubmit;
  final String title;
  final String? hint;

  const _SearchAppBar({
    required this.onSubmit,
    required this.title,
    this.hint,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<_SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<_SearchAppBar> {
  final _controller = TextEditingController();
  int _unread = 0;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    setState(() => _fetching = true);
    try {
      final repo = context.read<SearchStockRepository>();
      final resp = await repo.getUserNews();
      if (resp['success'] == true) {
        setState(() => _unread = resp['unread_count'] ?? 0);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _fetching = false);
    }
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) widget.onSubmit(q);
  }

  void _openNotiScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    if (result == true) {
      _fetchUnread(); // Refresh unread after return
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.only(right: 8),
        height: 40,
        alignment: Alignment.center,
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Nhập mã cổ phiếu...',
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: Icon(Icons.search, color: theme.colorScheme.primary),
              onPressed: _submit,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications, color: theme.colorScheme.onSurface),
                tooltip: 'Thông báo',
                onPressed: _fetching ? null : _openNotiScreen,
              ),
            ),
            if (_unread > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ],
      backgroundColor: theme.colorScheme.surface,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
      centerTitle: false,
    );
  }
}
