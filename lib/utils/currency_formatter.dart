import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );

  static String format(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatThousanDong(double amount) {
    return _currencyFormatter.format(amount * 1000);
  }
}
