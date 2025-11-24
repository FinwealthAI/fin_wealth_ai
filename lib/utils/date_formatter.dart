import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yy');

  static String format(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateFromString(String inputDate) {
    final DateFormat inputFormat = DateFormat('yyyy-MM-dd');
    final DateFormat outputFormat = DateFormat('dd/MM/yyyy');
    final DateTime dateTime = inputFormat.parse(inputDate);
    return outputFormat.format(dateTime);
  }

  static String formatExpiryDate(int numberOfDays) {
    // Calculate the expiry date
    final currentDate = DateTime.now();
    final expiryDate = currentDate.add(Duration(days: numberOfDays));

    // Format the expiry date
    final DateFormat dateFormat =
        DateFormat('dd/MM/yyyy'); // Adjust the format as needed
    return dateFormat.format(expiryDate);
  }
}
