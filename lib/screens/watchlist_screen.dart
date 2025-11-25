import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/blocs/watchlist/watchlist_bloc.dart';
import 'package:fin_wealth/blocs/watchlist/watchlist_event.dart';
import 'package:fin_wealth/blocs/watchlist/watchlist_state.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  void _showAddTickerDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm cổ phiếu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập mã cổ phiếu (VD: FPT)'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final ticker = controller.text.trim().toUpperCase();
              if (ticker.isNotEmpty) {
                context.read<WatchlistBloc>().add(AddToWatchlist(ticker));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => WatchlistBloc(
        repository: context.read<WatchlistRepository>(),
      )..add(LoadWatchlist()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Danh sách theo dõi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddTickerDialog(context),
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.surfaceContainer.withOpacity(0.9),
                  ],
                ),
              ),
              child: BlocConsumer<WatchlistBloc, WatchlistState>(
                listener: (context, state) {
                  if (state is WatchlistError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is WatchlistLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is WatchlistLoaded) {
                    if (state.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Danh sách trống',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<WatchlistBloc>().add(LoadWatchlist());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  item.ticker.substring(0, 1),
                                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                                ),
                              ),
                              title: Text(
                                item.ticker,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.companyName != null)
                                    Text(
                                      item.companyName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                  if (item.currentPrice != null)
                                    Row(
                                      children: [
                                        Text(
                                          '${item.currentPrice}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.changePercent}%',
                                          style: TextStyle(
                                            color: (item.changePercent ?? 0) >= 0 ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xác nhận'),
                                      content: Text('Bạn có chắc muốn xóa ${item.ticker} khỏi danh sách?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.read<WatchlistBloc>().add(RemoveFromWatchlist(item.id));
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is WatchlistError) {
                     return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Lỗi: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<WatchlistBloc>().add(LoadWatchlist()),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('Loading...'));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
