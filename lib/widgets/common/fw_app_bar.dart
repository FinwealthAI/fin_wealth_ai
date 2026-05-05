import 'package:flutter/material.dart';
import '../../screens/v2/root_shell_v2.dart' show RootShellNav;
import '../../screens/v2/stock_search_screen_v2.dart';
import '../../theme/theme.dart';

class FwAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final bool showHome;
  final bool showSearch;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const FwAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.showHome = true,
    this.showSearch = true,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();

    final mergedActions = <Widget>[
      ...actions,
      if (showSearch)
        IconButton(
          tooltip: 'Tìm cổ phiếu',
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const StockSearchScreenV2()),
            );
          },
        ),
      if (showHome && canPop)
        IconButton(
          tooltip: 'Trang chủ',
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            RootShellNav.goHome();
          },
        ),
    ];

    return AppBar(
      automaticallyImplyLeading: showBack || canPop,
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          if (subtitle != null)
            Text(subtitle!,
                style: text.bodySmall?.copyWith(color: AppColors.darkTextMuted)),
        ],
      ),
      actions: mergedActions,
      bottom: bottom,
    );
  }
}
