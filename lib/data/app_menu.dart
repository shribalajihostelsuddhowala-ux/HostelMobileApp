import 'package:flutter/material.dart';

import '../models/menu_item.dart';

/// The application menu, in the same sections and order as the desktop
/// MainForm.BuildNavigation(). Backup / Restore is left out: the database is
/// in Supabase, which backs itself up. Application Settings has only the
/// academic year.
const List<MenuItem> appMenu = [
  MenuItem(
    group: 'OVERVIEW',
    title: 'Dashboard',
    description: 'Summary of students, rooms, payments and dues.',
    icon: Icons.dashboard_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'HOSTEL',
    title: 'Hostels',
    description: 'Add and edit hostels.',
    icon: Icons.apartment,
  ),
  MenuItem(
    group: 'HOSTEL',
    title: 'Colleges',
    description: 'Colleges whose students stay in the selected hostel.',
    icon: Icons.school_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'HOSTEL',
    title: 'Rooms',
    description: 'Rooms, sharing (number of beds), occupancy and free beds.',
    icon: Icons.meeting_room_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'HOSTEL',
    title: 'Room Allocation',
    description:
        "Check-in with the student's yearly fee, room transfer and check-out.",
    icon: Icons.bed_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'STUDENTS',
    title: 'Students',
    description:
        'Student records, father and mother, photos, Aadhaar cards and I-cards.',
    icon: Icons.people_outline,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'STUDENTS',
    title: 'Attendance',
    description:
        'Night attendance, and emails to the parents of absent students.',
    icon: Icons.fact_check_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'BILLING',
    title: 'Invoices',
    description:
        'Yearly fee per student: rent and transport, paid and pending.',
    icon: Icons.receipt_long_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'BILLING',
    title: 'Payments',
    description: 'Record payments in any number of instalments.',
    icon: Icons.payments_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'BILLING',
    title: 'Fee Reminders',
    description: 'Pending fees, and fee reminders to the father (or mother).',
    icon: Icons.notifications_active_outlined,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'BILLING',
    title: 'Reports',
    description: 'Student, room, payment, fee and pending fee reports.',
    icon: Icons.bar_chart,
    requiresHostel: true,
  ),
  MenuItem(
    group: 'SETTINGS',
    title: 'Admin Account',
    description: "The admin's email and phone.",
    icon: Icons.manage_accounts_outlined,
  ),
  MenuItem(
    group: 'SETTINGS',
    title: 'Email Settings',
    description: 'Email texts and the history of messages sent.',
    icon: Icons.email_outlined,
  ),
  MenuItem(
    group: 'SETTINGS',
    title: 'Application Settings',
    description: 'The month the academic year starts.',
    icon: Icons.settings_outlined,
  ),
];
