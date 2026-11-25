import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_mobile_app/data/billing_repository.dart';
import 'package:hostel_mobile_app/data/settings_repository.dart';
import 'package:hostel_mobile_app/screens/application_settings_screen.dart';
import 'package:hostel_mobile_app/services/academic_year_service.dart';
import 'package:hostel_mobile_app/services/validators.dart';
import 'package:hostel_mobile_app/theme/app_theme.dart';

class FakeBilling extends BillingRepository {
  FakeBilling(this.month);
  int month;
  @override
  Future<int> getAcademicYearStartMonth() async => month;
}

class FakeSettings extends SettingsRepository {
  final saved = <int>[];
  bool fail = false;
  @override
  Future<void> saveAcademicYearStartMonth(int month) async {
    if (fail) throw Exception('offline');
    saved.add(month);
  }
}

void main() {
  late FakeSettings settings;

  setUp(() {
    settings = FakeSettings();
    SettingsRepository.useInstance(settings);
    BillingRepository.useInstance(FakeBilling(7));
  });
  tearDown(() {
    SettingsRepository.useInstance(null);
    BillingRepository.useInstance(null);
  });

  group('AcademicYearService', () {
    test('when a year ends', () {
      expect(AcademicYearService.endText(7), '30 June (the next year)');
      expect(AcademicYearService.endText(1), '31 December (the same year)');
      expect(AcademicYearService.endText(4), '31 March (the next year)');
      expect(AcademicYearService.endText(3), '28 February (the next year)');
      expect(AcademicYearService.endText(12), '30 November (the next year)');
    });

    test('the year today falls in', () {
      expect(
        AcademicYearService.currentYearText(7, DateTime(2026, 11, 25)),
        '2026-2027: 1 Jul 2026 to 30 Jun 2027',
      );
      expect(
        AcademicYearService.currentYearText(7, DateTime(2026, 3, 1)),
        '2025-2026: 1 Jul 2025 to 30 Jun 2026',
      );
      expect(
        AcademicYearService.currentYearText(1, DateTime(2026, 11, 25)),
        '2026: 1 Jan 2026 to 31 Dec 2026',
      );
      expect(
        AcademicYearService.currentYearText(4, DateTime(2026, 11, 25)),
        '2026-2027: 1 Apr 2026 to 31 Mar 2027',
      );
      expect(
        AcademicYearService.currentYearText(7, DateTime(2026, 7, 1)),
        '2026-2027: 1 Jul 2026 to 30 Jun 2027',
      );
    });

    test('month names', () {
      expect(AcademicYearService.monthName(1), 'January');
      expect(AcademicYearService.monthName(12), 'December');
    });

    test('only months 1 to 12 are saved', () async {
      for (final bad in [0, 13, -1]) {
        await expectLater(
          AcademicYearService.save(bad),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Please choose the month the academic year starts in.',
            ),
          ),
        );
      }
      expect(settings.saved, isEmpty);
      await AcademicYearService.save(4);
      expect(settings.saved, [4]);
    });
  });

  group('Application Settings screen', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ApplicationSettingsScreen(today: DateTime(2026, 11, 25)),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, String month) async {
      await tester.tap(find.byKey(const Key('startMonth')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 $month').last);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the saved month with its preview', (tester) async {
      await open(tester);
      expect(find.text('1 July'), findsOneWidget);
      expect(find.text('30 June (the next year)'), findsOneWidget);
      expect(find.text('2026-2027: 1 Jul 2026 to 30 Jun 2027'), findsOneWidget);
    });

    testWidgets('another month updates the preview before saving', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, 'January');
      expect(find.text('31 December (the same year)'), findsOneWidget);
      expect(find.text('2026: 1 Jan 2026 to 31 Dec 2026'), findsOneWidget);
      expect(settings.saved, isEmpty);
    });

    testWidgets('no change says so and saves nothing', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('saveYear')));
      await tester.pumpAndSettle();
      expect(find.text('No change.'), findsOneWidget);
      expect(settings.saved, isEmpty);
    });

    testWidgets('a change asks first; Cancel keeps the old month', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, 'April');
      await tester.tap(find.byKey(const Key('saveYear')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Start the academic year on 1 April from now on?'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fees already made keep their academic year.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(settings.saved, isEmpty);
    });

    testWidgets('Change saves the new month', (tester) async {
      await open(tester);
      await choose(tester, 'April');
      await tester.tap(find.byKey(const Key('saveYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmYear')));
      await tester.pumpAndSettle();
      expect(settings.saved, [4]);
      expect(find.text('Saved.'), findsOneWidget);
      // Saving the same month again is "No change".
      await tester.tap(find.byKey(const Key('saveYear')));
      await tester.pumpAndSettle();
      expect(find.text('No change.'), findsOneWidget);
    });

    testWidgets('a failed save is reported and the month stays', (
      tester,
    ) async {
      settings.fail = true;
      await open(tester);
      await choose(tester, 'March');
      await tester.tap(find.byKey(const Key('saveYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmYear')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The academic year could not be saved.'),
        findsOneWidget,
      );
      expect(settings.saved, isEmpty);
    });
  });
}
