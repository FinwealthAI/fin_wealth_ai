import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockHeaderSliver extends StatelessWidget {
  final Map<String, dynamic> overviewData;
  final String ticker;
  final bool isFollowing; // Placeholder for now

  const StockHeaderSliver({
    super.key,
    required this.overviewData,
    required this.ticker,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _parseValue(overviewData['price']);
    final change = _parseValue(overviewData['change']);
    final changePercent = _parseValue(overviewData['change_percent']);
    final companyName = overviewData['company_name'] ?? 'Công ty Cổ phần...';

    final priceFmt = NumberFormat('#,##0', 'vi_VN').format(price);
    final changeFmt = NumberFormat('#,##0', 'vi_VN').format(change.abs());
    final changePercentFmt = NumberFormat('0.00', 'vi_VN').format(changePercent.abs());
    
    final isUp = change >= 0;
    final color = isUp ? Colors.green : Colors.red;
    final prefix = isUp ? '+' : '-';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 135.0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(isFollowing ? Icons.star : Icons.star_border, color: Colors.amber),
          onPressed: () {
             // TODO: Toggle follow
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        expandedTitleScale: 1.2,
        title: LayoutBuilder(
          builder: (context, constraints) {
             // Adjust visibility based on collapse state if needed
             return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.onSurface,
                    fontSize: 16, 
                  )
                ),
              ],
            );
          }
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // Price on the right or customized layout
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               // We can put price here or align it differently. 
               // For now, let's put price info on the right side of the expanded header
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         priceFmt,
                         style: theme.textTheme.headlineMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: theme.colorScheme.onSurface,
                         ),
                       ),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                             color: color,
                           ),
                           Text(
                             '$prefix$changeFmt ($prefix$changePercentFmt%)',
                             style: TextStyle(
                               color: color,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ],
               )
            ],
          ),
        ),
      ),
    );
  }
}

double _parseValue(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return 0.0;
    String clean = value.replaceAll(',', '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}
