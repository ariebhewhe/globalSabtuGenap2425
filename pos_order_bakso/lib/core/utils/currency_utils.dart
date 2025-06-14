import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatToRupiah(num price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }
}
