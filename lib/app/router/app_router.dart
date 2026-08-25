import 'package:alfred/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    // initialLocation: RouteNames.home,
    initialLocation: RouteNames.subjects,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Home')));
        },
      ),


      GoRoute(
        path: RouteNames.events,
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Events')));
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
