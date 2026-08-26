import 'package:alfred/features/events/presentation/screens/events_screen.dart';
import 'package:alfred/features/home/presentation/screens/home_screen.dart';
import 'package:alfred/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:alfred/features/timetable/presentation/screens/create_class_screen.dart';
import 'package:alfred/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,
    //  initialLocation: RouteNames.events,
    routes: [
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: RouteNames.timetable,
        name: 'timetable',
        builder: (context, state) {
          return const TimetableScreen();
        },
      ),
      GoRoute(
        path: '${RouteNames.timetable}/create',
        name: 'create-class',
        builder: (context, state) {
          return const CreateClassScreen();
        },
      ),
      GoRoute(
        path: RouteNames.events,
        name: 'events',
        builder: (context, state) {
          return const EventsScreen();
        },
      ),

      GoRoute(
        path: RouteNames.attendance,
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Attendance')));
        },
      ),

      GoRoute(
        path: RouteNames.marks,
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Marks')));
        },
      ),

      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Settings')));
        },
      ),
      GoRoute(
        path: RouteNames.subjects,
        builder: (context, state) {
          return const SubjectsScreen();
        },
      ),
    ],
  );
}
