import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'ai_toolbox_screen_v2.dart';
import 'blog_screen_v2.dart';
import 'chat_screen_v2.dart';
import 'home_screen_v2.dart';
import 'mindmap_screen_v2.dart';
import 'profile_screen_v2.dart';
import 'reports_screen_v2.dart';
import 'screener_screen_v2.dart';
import 'stock_search_screen_v2.dart';
import 'strategy_screen_v2.dart';

class RootShellNav {
  static final GlobalKey<RootShellV2State> key =
      GlobalKey<RootShellV2State>();

  static void goHome() {
    key.currentState?.setIndex(0);
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
    const _MoreMenuScreen(),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPrimary,
        onPressed: _openToolbox,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.purpleGlow,
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ),
      ),
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
            icon: Icon(Icons.more_horiz),
            selectedIcon:
                Icon(Icons.more_horiz, color: AppColors.brandPrimaryDark),
            label: 'Thêm',
          ),
        ],
      ),
    );
  }
}

class _MoreMenuScreen extends StatelessWidget {
  const _MoreMenuScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.tune_outlined, 'Lọc cổ phiếu', () => _push(context, const ScreenerScreenV2())),
      (Icons.account_tree_outlined, 'Sơ đồ kinh tế', () => _push(context, const MindmapScreenV2())),
      (Icons.chat_bubble_outline, 'Chat Mr.Wealth', () => _push(context, const ChatScreenV2())),
      (Icons.favorite_outline, 'Watchlist', () {}),
      (Icons.calculate_outlined, 'Tính margin', () {}),
      (Icons.person_outline, 'Tài khoản', () => _push(context, const ProfileScreenV2())),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm'),
        actions: [
          IconButton(
            tooltip: 'Tìm cổ phiếu',
            icon: const Icon(Icons.search),
            onPressed: () => _push(context, const StockSearchScreenV2()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          for (final item in items) ...[
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child:
                    Icon(item.$1, color: AppColors.brandPrimaryDark, size: 20),
              ),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.darkTextMuted),
              onTap: item.$3,
            ),
            const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }

  static void _push(BuildContext c, Widget w) {
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));
  }
}
