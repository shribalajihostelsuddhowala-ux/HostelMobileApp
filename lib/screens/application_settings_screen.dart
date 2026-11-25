import 'package:flutter/material.dart';

import '../services/academic_year_service.dart';
import '../services/validators.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Application Settings (the desktop screen): the month the academic year
/// starts in. Fees, invoice numbers, the dashboard, reports and I-cards
/// follow it.
class ApplicationSettingsScreen extends StatefulWidget {
  const ApplicationSettingsScreen({super.key, this.today});

  /// Today's date; only the automated tests set it.
  final DateTime? today;

  @override
  State<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState extends State<ApplicationSettingsScreen> {
  late final Future<void> _loaded = _load();
  int _saved = 7;
  int _month = 7;
  String _message = '';
  bool _ok = false;
  bool _busy = false;

  Future<void> _load() async {
    _saved = await AcademicYearService.get();
    _month = _saved;
  }

  DateTime get _today => widget.today ?? DateTime.now();

  Future<void> _save() async {
    if (_busy) return;
    if (_month == _saved) {
      setState(() {
        _ok = true;
        _message = 'No change.';
      });
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Academic year'),
        content: Text(
          'Start the academic year on 1 ${AcademicYearService.monthName(_month)} '
          'from now on?\n\nNew fees, invoice numbers, the dashboard, reports '
          'and I-cards will use the new year. Fees already made keep their '
          'academic year.',
          key: const Key('yearConfirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirmYear'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await AcademicYearService.save(_month);
      if (!mounted) return;
      setState(() {
        _saved = _month;
        _ok = true;
        _message = 'Saved.';
      });
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _ok = false;
          _message = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'The academic year could not be saved. $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Settings')),
      body: FutureBuilder<void>(
        future: _loaded,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return InfoView(
              key: const Key('settingsError'),
              icon: Icons.cloud_off,
              text:
                  'The settings could not be loaded.\n${snapshot.error}\n\n'
                  'Close this screen and open it again to try again.',
            );
          }
          return SafeArea(
            child: ListView(
              key: const Key('settingsView'),
              padding: const EdgeInsets.all(16),
              children: [
                const FormSection('Academic year'),
                FormDropdown<int>(
                  key: const Key('startMonth'),
                  label: 'Starts on',
                  value: _month,
                  enabled: !_busy,
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(
                        value: m,
                        child: Text('1 ${AcademicYearService.monthName(m)}'),
                      ),
                  ],
                  onChanged: (m) => setState(() {
                    _month = m ?? _month;
                    _message = '';
                  }),
                ),
                _row(
                  'Ends on',
                  AcademicYearService.endText(_month),
                  'yearEnds',
                ),
                _row(
                  'Current year',
                  AcademicYearService.currentYearText(_month, _today),
                  'yearCurrent',
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Fees, invoice numbers, the dashboard, reports and '
                    'I-cards follow this year.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _message,
                      key: const Key('yearMessage'),
                      style: TextStyle(
                        color: _ok
                            ? const Color(0xFF198754)
                            : const Color(0xFFC0392B),
                      ),
                    ),
                  ),
                SaveButton(
                  key: const Key('saveYear'),
                  busy: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, String key) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        Expanded(child: Text(value, key: Key(key))),
      ],
    ),
  );
}
