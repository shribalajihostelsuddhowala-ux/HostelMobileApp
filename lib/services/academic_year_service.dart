import '../data/billing_repository.dart';
import '../data/settings_repository.dart';
import 'money.dart';
import 'validators.dart';

/// The month the academic year starts in, chosen in Application Settings and
/// kept in app_setting "AcademicYear.StartMonth" (July when none is saved).
/// Fees, invoice numbers, the dashboard, reports and I-cards all follow it.
/// As the desktop AcademicYearService.
class AcademicYearService {
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _short = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String monthName(int month) => monthNames[month - 1];

  /// "30 June (the next year)": when a year with this start month ends.
  static String endText(int startMonth) {
    // A year starting on the 1st of [startMonth] ends the day before the same
    // day a year later.
    final end = DateTime(2002, startMonth, 1).subtract(const Duration(days: 1));
    return '${end.day} ${monthName(end.month)}'
        '${startMonth == 1 ? ' (the same year)' : ' (the next year)'}';
  }

  /// "2026-2027: 1 Jul 2026 to 30 Jun 2027": the year today falls in.
  static String currentYearText(int startMonth, DateTime today) {
    final startYear = today.month >= startMonth ? today.year : today.year - 1;
    final start = DateTime(startYear, startMonth, 1);
    final end = DateTime(
      startYear + 1,
      startMonth,
      1,
    ).subtract(const Duration(days: 1));
    String d(DateTime x) => '${x.day} ${_short[x.month - 1]} ${x.year}';
    return '${AcademicYear.label(startYear, startMonth)}: '
        '${d(start)} to ${d(end)}';
  }

  /// The saved start month.
  static Future<int> get() =>
      BillingRepository.instance.getAcademicYearStartMonth();

  /// Saves a new start month. Fees already made keep their academic year.
  static Future<void> save(int month) async {
    if (month < 1 || month > 12) {
      throw const ValidationException(
        'Please choose the month the academic year starts in.',
      );
    }
    await SettingsRepository.instance.saveAcademicYearStartMonth(month);
  }
}
