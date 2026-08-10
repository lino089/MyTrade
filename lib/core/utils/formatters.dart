import 'package:intl/intl.dart';

class Formatters {
  static final _percentFormat = NumberFormat.decimalPattern('en_US');
  static final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  static final _uscFormat = NumberFormat.decimalPattern('en_US');
  static final _idrFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  static String formatCurrency(double value, [String currency = 'USD']) {
    final sign = value >= 0 ? '' : '-';
    final absVal = value.abs();
    
    if (currency == 'USD') {
      return '$sign${_usdFormat.format(absVal)}';
    } else if (currency == 'USC') {
      return '$sign${_uscFormat.format(absVal)} USC';
    } else if (currency == 'IDR') {
      return '$sign${_idrFormat.format(absVal)}';
    } else {
      return '$sign\$${absVal.toStringAsFixed(2)}';
    }
  }

  static String formatPercent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${_percentFormat.format(value)}%';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDuration(DateTime entry, DateTime? exit) {
    if (exit == null) return '-';
    final diff = exit.difference(entry);
    if (diff.inDays > 0) {
      return '${diff.inDays}h ${diff.inHours % 24}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}j ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}
