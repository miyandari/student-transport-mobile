import 'package:shamsi_date/shamsi_date.dart';

class PersianDateUtils {
  PersianDateUtils._();

  static const List<String> _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  static String toPersianDigits(String value) {
    final buffer = StringBuffer();

    for (final char in value.split('')) {
      final digit = int.tryParse(char);

      if (digit != null && digit >= 0 && digit <= 9) {
        buffer.write(_persianDigits[digit]);
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  static String formatDate(DateTime dateTime) {
    final date = Jalali.fromDateTime(dateTime);

    final day = toPersianDigits(
      date.day.toString(),
    );

    final month = monthName(date.month);

    final year = toPersianDigits(
      date.year.toString(),
    );

    return '$day $month $year';
  }

  static String formatDateShort(DateTime dateTime) {
    final date = Jalali.fromDateTime(dateTime);

    final value =
        '${date.year.toString().padLeft(4, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';

    return toPersianDigits(value);
  }

  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour
        .toString()
        .padLeft(2, '0');

    final minute = dateTime.minute
        .toString()
        .padLeft(2, '0');

    return toPersianDigits(
      '$hour:$minute',
    );
  }

  static String monthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return months[month - 1];
  }
}