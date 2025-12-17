import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:intl/intl.dart';

class CtckTable extends StatefulWidget {
  final String ticker;
  const CtckTable({super.key, required this.ticker});

  @override
  State<CtckTable> createState() => _CtckTableState();
}

class _CtckTableState extends State<CtckTable> {
  late SearchStockRepository _repo;
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _repo = context.read<SearchStockRepository>();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _repo.getValuation(widget.ticker);
      if (mounted) {
        setState(() {
          // Correct key is 'details' per backend MarketDataService.get_valuation_details
          if (res['details'] is List) {
             _data = res['details'];
          } else if (res['data'] is List) {
             _data = res['data'];
          } else {
             _data = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     if (_isLoading) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (_data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Chưa có đánh giá từ CTCK')),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataTable(
                columnSpacing: 12,
                headingRowHeight: 40,
                horizontalMargin: 8,
                columns: const [
                  DataColumn(label: Text('CTCK')),
                  DataColumn(label: Text('Mục tiêu')),
                  DataColumn(label: Text('Ngày')),
                ],
                rows: _data.take(5).map<DataRow>((item) {
                  // Map backend keys: firm_new, target_price, report_date
                  final price = _parseValue(item['target_price'] ?? item['price_target'] ?? 0); 
                  final priceFmt = NumberFormat('#,##0', 'vi_VN').format(price);

                  return DataRow(cells: [
                     DataCell(SizedBox(
                       width: 100,
                       child: Text(
                         item['firm_new'] ?? item['ctck_name'] ?? '--',
                         style: const TextStyle(fontWeight: FontWeight.bold),
                         softWrap: true,
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                       ),
                     )),
                     DataCell(Text(priceFmt)),
                     DataCell(Text(item['report_date'] ?? item['date'] ?? '--')),
                  ]);
                }).toList(),
              ),
          ],
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
