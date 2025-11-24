Widget buildStockValuationTable(List<StockValuation> stocks) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Cổ phiếu')),
        DataColumn(label: Text('Ngày BC gần nhất')),
        DataColumn(label: Text('Số CTCK khuyến nghị')),
        DataColumn(label: Text('Định giá trung bình')),
        DataColumn(label: Text('Chênh lệch định giá (%)')),
        DataColumn(label: Text('Giá đầu tư')),
        DataColumn(label: Text('Chênh lệch giá đầu tư (%)')),
        DataColumn(label: Text('Báo cáo AI')),
      ],
      rows: stocks.map((stock) {
        return DataRow(cells: [
          DataCell(Text(stock.ticker)),
          DataCell(Text(stock.lastReportDate)),
          DataCell(Text(stock.recommendCount.toString())),
          DataCell(Text(stock.averageTargetPrice.toString())),
          DataCell(Text('${stock.valuationDifference}%')),
          DataCell(Text(stock.investPrice.toString())),
          DataCell(Text('${stock.investPriceDifference}%')),
          DataCell(TextButton(onPressed: () {}, child: Text('Xem'))),
        ]);
      }).toList(),
    ),
  );
}