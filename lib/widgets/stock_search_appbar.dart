import 'package:flutter/material.dart';

class StockSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const StockSearchAppBar({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<StockSearchAppBar> createState() => _StockSearchAppBarState();
}

class _StockSearchAppBarState extends State<StockSearchAppBar> {
  final _controller = TextEditingController();

  void _doSubmit() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) widget.onSubmit(q);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 8,
      title: SizedBox(
        height: 40,
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _doSubmit(),
          decoration: InputDecoration(
            hintText: 'Nhập mã chứng khoán',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _doSubmit,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0.5,
    );
  }
}
