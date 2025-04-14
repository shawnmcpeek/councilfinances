import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_US',
  symbol: '\$',
);

final _dateFormatter = DateFormat('MM/dd/yyyy');

String formatCurrency(double amount) {
  return _currencyFormatter.format(amount);
}

String formatDate(DateTime date) {
  return _dateFormatter.format(date);
}

String formatMonth(int month) {
  return DateFormat('MMMM').format(DateTime(2024, month));
}

String formatTime(DateTime time) {
  return DateFormat('h:mm a').format(time);
} 