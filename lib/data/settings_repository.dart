import 'package:flutter/foundation.dart';

import 'database.dart';

/// Settings the desktop keeps in the AppSetting table, and the admin's phone.
class SettingsRepository {
  static SettingsRepository? _testInstance;

  static SettingsRepository get instance =>
      _testInstance ?? SettingsRepository();

  @visibleForTesting
  static void useInstance(SettingsRepository? repository) =>
      _testInstance = repository;

  /// The WhatsApp texts the admin saved on the desktop (Email Settings >
  /// WhatsApp), by key; missing keys are not in the map.
  Future<Map<String, String>> getWhatsAppTexts() async {
    final rows = await Database.client
        .from('app_setting')
        .select('setting_key, setting_value')
        .inFilter('setting_key', [
          'WhatsApp.FeeText',
          'WhatsApp.AttendanceText',
        ]);
    return {
      for (final r in rows)
        if ((r['setting_value'] as String?)?.trim().isNotEmpty ?? false)
          r['setting_key'] as String: r['setting_value'] as String,
    };
  }

  /// The first admin's phone (parents are asked to call it when the hostel
  /// has no phone), or null.
  Future<String?> getAdminPhone() async {
    final rows = await Database.client
        .from('admin_user')
        .select('phone')
        .order('admin_user_id')
        .limit(1);
    return rows.isEmpty ? null : rows.first['phone'] as String?;
  }

  /// Saves the month the academic year starts in (app_setting
  /// "AcademicYear.StartMonth"); the database functions follow it at once.
  Future<void> saveAcademicYearStartMonth(int month) async {
    await Database.client.from('app_setting').upsert({
      'setting_key': 'AcademicYear.StartMonth',
      'setting_value': '$month',
    }, onConflict: 'setting_key');
  }
}
