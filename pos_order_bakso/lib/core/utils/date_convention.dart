import 'package:intl/intl.dart';

class DateConvention {
  static String formatToIndoConv(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }
}
