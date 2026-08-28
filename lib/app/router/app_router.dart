import 'package:alfred/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:alfred/features/events/presentation/screens/create_event_screen.dart';
import 'package:alfred/features/events/presentation/screens/events_screen.dart';
import 'package:alfred/features/home/presentation/screens/home_screen.dart';
import 'package:alfred/features/marks/presentation/screens/marks_screen.dart';
import 'package:alfred/features/notes/presentation/screens/notes_screen.dart';
import 'package:alfred/features/settings/presentation/screens/setting_screen.dart';
import 'package:alfred/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:alfred/features/timetable/presentation/screens/create_class_screen.dart';
import 'package:alfred/features/timetable/presentation/screens/timetable_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/main_shell.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,

    routes: [
      // ==========================================================
      // GLOBAL BOTTOM NAVIGATION SHELL
      //
      // Index:
      // 0 = Home
      // 1 = Timetable
      // 2 = Marks
      // 3 = Attendance
      // 4 = More
      // ==========================================================
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainShell(navigationShell: navigationShell);
            },

        branches: [
          // ======================================================
          // 0 - HOME
          // ======================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: 'home',
                builder: (context, state) {
                  return const HomeScreen();
                },
              ),
            ],
          ),

          // ======================================================
          // 1 - TIMETABLE
          // ======================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.timetable,
                name: 'timetable',
                builder: (context, state) {
                  return const TimetableScreen();
                },
              ),
            ],
          ),

          // ======================================================
          // 2 - MARKS
          // ======================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.marks,
                name: 'marks',
                builder: (context, state) {
                  return const MarksScreen();
                },
              ),
            ],
          ),

          // ======================================================
          // 3 - ATTENDANCE
          // ======================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.attendance,
                name: 'attendance',
                builder: (context, state) {
                  return const AttendanceScreen();
                },
              ),
            ],
          ),

          // ======================================================
          // 4 - MORE
          // ======================================================
          StatefulShellBranch(
            routes: [
              // ==========================================================
              // SETTINGS
              // ==========================================================
              GoRoute(
                path: RouteNames.more,
                name: 'more',
                builder: (context, state) {
                  return const SettingsScreen();
                },
              ),
            ],
          ),
        ],
      ),

      // ==========================================================
      // SUBJECTS
      //
      // NOT a bottom navigation destination.
      // ==========================================================
      GoRoute(
        path: RouteNames.subjects,
        name: 'subjects',
        builder: (context, state) {
          return const SubjectsScreen();
        },
      ),

      // ==========================================================
      // SUBJECT NOTES
      //
      // This opens the REAL NotesScreen.
      // No SubjectWorkspaceScreen.
      // ==========================================================
      GoRoute(
        path: '${RouteNames.subjects}/:subjectId',
        name: 'notes',
        builder: (context, state) {
          final subjectId = int.parse(state.pathParameters['subjectId']!);

          final subjectName = state.uri.queryParameters['name'] ?? 'Subject';

          return NotesScreen(subjectId: subjectId, subjectName: subjectName);
        },
      ),

      // ==========================================================
      // EVENTS
      // ==========================================================
      GoRoute(
        path: RouteNames.events,
        name: 'events',
        builder: (context, state) {
          return const EventsScreen();
        },
      ),

      // ==========================================================
      // CREATE EVENT
      // ==========================================================
      GoRoute(
        path: '${RouteNames.events}/create',
        name: 'create-event',
        builder: (context, state) {
          return const CreateEventScreen();
        },
      ),

      // ==========================================================
      // CREATE CLASS
      // ==========================================================
      GoRoute(
        path: '${RouteNames.timetable}/create',
        name: 'create-class',
        builder: (context, state) {
          return const CreateClassScreen();
        },
      ),

      // ==========================================================
      // SETTINGS
      // ==========================================================
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Settings')));
        },
      ),
    ],
  );
}

// ================================================================
// TEMPORARY MORE SCREEN
//
// Replace this with your real MoreScreen when you create it.
// ================================================================
class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.push(RouteNames.settings);
            },
          ),
        ],
      ),
    );
  }
}
