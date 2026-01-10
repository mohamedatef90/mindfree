import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:mindfree/features/home/presentation/home_screen.dart';
import 'package:mindfree/features/projects/presentation/projects_view.dart';
import 'package:mindfree/features/tasks/presentation/tasks_view.dart';
import 'package:mindfree/features/calendar/presentation/calendar_view.dart';
import 'package:mindfree/features/dashboard/presentation/dashboard_view.dart';
import 'package:mindfree/features/projects/presentation/project_detail_view.dart';
import 'package:mindfree/features/notes/presentation/note_editor_view.dart';
import 'package:mindfree/features/notes/presentation/notes_list_view.dart';
import 'package:mindfree/features/splash/presentation/splash_view.dart';
import 'package:mindfree/features/settings/presentation/settings_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Custom iOS-style page with swipe back gesture support
/// Uses CupertinoPageTransition on iOS, FadeTransition on Android
class SwipeBackPage<T> extends CustomTransitionPage<T> {
  SwipeBackPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (Platform.isIOS) {
              return CupertinoPageTransition(
                primaryRouteAnimation: animation,
                secondaryRouteAnimation: secondaryAnimation,
                linearTransition: false,
                child: child,
              );
            }
            // Android uses a smooth fade transition
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashView(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: const DashboardView(),
            ),
          ),
          GoRoute(
            path: '/note_list',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: const NotesListView(),
            ),
          ),
          GoRoute(
            path: '/note_editor',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: NoteEditorView(note: state.extra as Note?),
            ),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: const ProjectsView(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: const TasksView(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => SwipeBackPage(
              key: state.pageKey,
              child: const CalendarView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/project/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SwipeBackPage(
            key: state.pageKey,
            child: ProjectDetailView(projectId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => SwipeBackPage(
          key: state.pageKey,
          child: const SettingsView(),
        ),
      ),
    ],
  );
}
