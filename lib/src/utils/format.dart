import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _iqd =
      NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع', decimalDigits: 0);

  static final NumberFormat _iqdWithDinar = NumberFormat('#,##0', 'ar_IQ');

  static String currencyIQD(num value) {
    return _iqd.format(value);
  }

  static String currencyIQDWithLabel(num value) {
    return '${_iqdWithDinar.format(value)} دينار';
  }
}
