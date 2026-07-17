import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
final _date = DateFormat('dd/MM/yyyy');

String formatCurrency(num value) => _currency.format(value);

String formatDate(DateTime? value) => value == null ? '—' : _date.format(value);

double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
