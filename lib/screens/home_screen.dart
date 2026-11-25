import 'package:flutter/material.dart';

import '../data/app_menu.dart';
import '../models/hostel.dart';
import '../models/menu_item.dart';
import '../services/auth_service.dart';
import '../services/hostel_selection.dart';
import '../theme/app_theme.dart';
import 'admin_account_screen.dart';
import 'allocations_screen.dart';
import 'application_settings_screen.dart';
import 'attendance_screen.dart';
import 'colleges_screen.dart';
import 'dashboard_screen.dart';
import 'email_settings_screen.dart';
import 'fee_reminders_screen.dart';
import 'feature_screen.dart';
import 'hostels_screen.dart';
import 'invoices_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'rooms_screen.dart';
import 'students_screen.dart';
import 'login_screen.dart';

/// Home page after sign in: the hostel to work on, then the menu of screens,
/// in the same sections as the desktop's left menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _selection = HostelSelection();
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = _selection.load();
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _selection.load();
    setState(() {
      _loading = next;
    });
    try {
      await next;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _pickHostel() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _HostelPicker(
        hostels: _selection.hostels,
        currentId: _selection.current?.hostelId,
      ),
    );
    if (chosen != null) await _selection.select(chosen);
  }

  void _open(MenuItem item) {
    final hostel = _selection.current;
    if (item.requiresHostel && hostel == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Add a hostel first, on the Hostels screen.'),
          ),
        );
      return;
    }
    _openScreen(item, hostel);
  }

  /// Opens the screen for a menu entry. Migrated screens open their own page;
  /// the others show what they will do.
  Future<void> _openScreen(MenuItem item, Hostel? hostel) async {
    final Widget screen = switch (item.title) {
      'Dashboard' => DashboardScreen(hostel: hostel!),
      'Hostels' => const HostelsScreen(),
      'Colleges' => CollegesScreen(hostel: hostel!),
      'Rooms' => RoomsScreen(hostel: hostel!),
      'Students' => StudentsScreen(hostel: hostel!),
      'Attendance' => AttendanceScreen(hostel: hostel!),
      'Room Allocation' => AllocationsScreen(hostel: hostel!),
      'Invoices' => InvoicesScreen(hostel: hostel!),
      'Payments' => PaymentsScreen(hostel: hostel!),
      'Fee Reminders' => FeeRemindersScreen(hostel: hostel!),
      'Reports' => ReportsScreen(hostel: hostel!),
      'Admin Account' => const AdminAccountScreen(),
      'Application Settings' => const ApplicationSettingsScreen(),
      'Email Settings' => const EmailSettingsScreen(),
      _ => FeatureScreen(
        item: item,
        hostel: item.requiresHostel ? hostel : null,
      ),
    };
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // Hostels may have been added, renamed or deleted.
    if (mounted && item.title == 'Hostels') await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          // Like the desktop, the header shows the hostel being worked on.
          title: Text(_selection.current?.hostelName ?? AppInfo.businessName),
          actions: [
            IconButton(
              key: const Key('signOut'),
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: _signOut,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<void>(
            future: _loading,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Message(
                  key: const Key('homeError'),
                  icon: Icons.cloud_off,
                  title: 'Could not load data from the database',
                  detail: '${snapshot.error}',
                );
              }
              return _buildMenu(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    final groups = <String>[];
    for (final item in appMenu) {
      if (!groups.contains(item.group)) groups.add(item.group);
    }

    return ListView(
      key: const Key('homeMenu'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HostelCard(
          hostel: _selection.current,
          canChange: _selection.hostels.length > 1,
          onChange: _pickHostel,
        ),
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              group,
              style: const TextStyle(
                color: AppColors.groupText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (final item in appMenu.where((i) => i.group == group))
                _MenuTile(
                  item: item,
                  enabled: !item.requiresHostel || _selection.current != null,
                  onTap: () => _open(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The selected hostel, with Change when there is more than one.
class _HostelCard extends StatelessWidget {
  const _HostelCard({
    required this.hostel,
    required this.canChange,
    required this.onChange,
  });

  final Hostel? hostel;
  final bool canChange;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('hostelCard'),
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: const Icon(
          Icons.apartment,
          color: AppColors.terracotta,
          size: 32,
        ),
        title: const Text(
          'Hostel',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        subtitle: Text(
          hostel?.hostelName ??
              'No hostels yet. Add one on the Hostels screen.',
          key: const Key('selectedHostel'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: hostel == null ? 14 : 17,
            fontWeight: hostel == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        trailing: canChange
            ? TextButton.icon(
                key: const Key('changeHostel'),
                onPressed: onChange,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change'),
              )
            : null,
        onTap: canChange ? onChange : null,
      ),
    );
  }
}

/// A square button on the menu.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.enabled,
    required this.onTap,
  });

  final MenuItem item;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = enabled ? AppColors.terracotta : AppColors.tileDisabled;
    return Card(
      key: Key('menu_${item.title}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: colour),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.tileDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The list of hostels to choose from, shown from the bottom of the screen.
class _HostelPicker extends StatelessWidget {
  const _HostelPicker({required this.hostels, required this.currentId});

  final List<Hostel> hostels;
  final int? currentId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Select the hostel to work on',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          for (final hostel in hostels)
            ListTile(
              key: Key('hostelOption_${hostel.hostelId}'),
              leading: const Icon(Icons.apartment),
              title: Text(hostel.hostelName),
              subtitle: hostel.address == null ? null : Text(hostel.address!),
              trailing: hostel.hostelId == currentId
                  ? const Icon(Icons.check, color: AppColors.terracotta)
                  : null,
              onTap: () => Navigator.of(context).pop(hostel.hostelId),
            ),
        ],
      ),
    );
  }
}

/// A centred icon and text; scrollable so pull to refresh works.
class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: AppColors.terracotta),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pull down to try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
