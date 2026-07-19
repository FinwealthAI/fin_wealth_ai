import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fin_wealth/utils/currency_formatter.dart';
import 'package:fin_wealth/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  group('CurrencyFormatter', () {
    test('format hiển thị số theo locale vi_VN kèm ký hiệu ₫', () {
      final result = CurrencyFormatter.format(1234567);
      expect(result, contains('₫'));
      expect(result, contains('1.234.567'));
    });

    test('formatThousanDong nhân 1000 trước khi format', () {
      final result = CurrencyFormatter.formatThousanDong(25.5);
      expect(result, contains('25.500'));
    });
  });

  group('DateFormatter', () {
    test('format trả về dd/MM/yy', () {
      expect(DateFormatter.format(DateTime(2026, 7, 10)), '10/07/26');
    });

    test('formatDateFromString chuyển yyyy-MM-dd sang dd/MM/yyyy', () {
      expect(DateFormatter.formatDateFromString('2026-01-05'), '05/01/2026');
    });
  });
}
