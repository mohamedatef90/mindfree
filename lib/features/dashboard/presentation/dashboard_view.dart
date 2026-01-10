import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/services/live_activity_service.dart';
import 'package:mindfree/features/projects/presentation/projects_controller.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/features/notes/presentation/notes_controller.dart';
import 'package:mindfree/features/settings/presentation/user_profile_controller.dart';
import 'package:mindfree/features/dashboard/presentation/dashboard_settings_controller.dart';
import 'package:mindfree/data/services/gemini_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindfree/data/models/task.dart';
import 'package:mindfree/data/models/project.dart';
import 'package:mindfree/data/models/note.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    // Update clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildInfoTip(String message) {
    return GestureDetector(
      onTap: () => _showInfoDialog(message),
      child: Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDashboardSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _DashboardSettingsSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Project>> projectsAsync = ref.watch(
      projectsControllerProvider,
    );
    final AsyncValue<List<Task>> tasksAsync = ref.watch(
      tasksControllerProvider,
    );
    final AsyncValue<List<Note>> notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksControllerProvider);
            ref.invalidate(projectsControllerProvider);
            ref.invalidate(allNotesProvider);
            ref.invalidate(taskStreakProvider);
          },
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildKineticHeader(),
                const SizedBox(height: 32),

                // Bento Grid Section
                _buildBentoGrid(tasksAsync, projectsAsync, notesAsync),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKineticHeader() {
    final avatarPath = ref.watch(userAvatarControllerProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Time Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_currentTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(_currentTime),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            Row(
              children: [
                // Dashboard Settings Button
                GestureDetector(
                  onTap: () => _showDashboardSettings(),
                  onLongPress: () {
                    if (Platform.isIOS) {
                      HapticFeedback.mediumImpact();
                    }
                    _showDashboardSettings();
                  },
                  child: const GlassCard(
                    borderRadius: 12,
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.dashboard_customize_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(width: 8),
                // Calendar Button
                GestureDetector(
                  onTap: () => context.push('/calendar'),
                  child: const GlassCard(
                    borderRadius: 12,
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(width: 8),
                // Profile Avatar
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: avatarPath != null && File(avatarPath).existsSync()
                              ? FileImage(File(avatarPath))
                              : const AssetImage('assets/images/logo.jpg') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).rotate(begin: -0.1),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Greeting Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                  ref.watch(userProfileControllerProvider).when(
                        data: (name) => Text(
                          name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
                              begin: const Offset(0.8, 0.8),
                            ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const Text('User'),
                      ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoGrid(
    AsyncValue<List<Task>> tasksAsync,
    AsyncValue<List<Project>> projectsAsync,
    AsyncValue<List<Note>> notesAsync,
  ) {
    final overdueTasksAsync = ref.watch(overdueTasksProvider);
    final settingsAsync = ref.watch(dashboardSettingsControllerProvider);

    final settings = settingsAsync.valueOrNull ?? DashboardSettings.defaults();

    // Build list of visible widgets in order
    final visibleWidgets = settings.widgetOrder
        .where((w) => !settings.hiddenWidgets.contains(w))
        .toList();

    // Helper to check if widget should be shown
    bool isVisible(DashboardWidget widget) => visibleWidgets.contains(widget);

    // Build a widget by its type
    Widget buildWidget(DashboardWidget widget) {
      switch (widget) {
        case DashboardWidget.dailyGoals:
          return _buildProgressCard(tasksAsync);
        case DashboardWidget.streak:
          return _buildStreakCard();
        case DashboardWidget.overdueTasks:
          return _buildOverdueTasksWidget(overdueTasksAsync, projectsAsync);
        case DashboardWidget.notes:
          return _buildNotesBento(notesAsync);
        case DashboardWidget.deadlines:
          return _buildDeadlinesBento(tasksAsync);
        case DashboardWidget.aiInsights:
          return _buildAIInsightsCard(tasksAsync);
        case DashboardWidget.focusTimer:
          return const CountdownTimerWidget();
        case DashboardWidget.projects:
          return _buildProjectsBento(projectsAsync, tasksAsync);
      }
    }

    final List<Widget> children = [];

    // Go through ordered widgets and build them
    for (final widget in visibleWidgets) {
      // Handle special row groupings for dailyGoals + streak and notes + deadlines
      if (widget == DashboardWidget.dailyGoals) {
        // Check if streak is also visible and comes right after
        final streakVisible = isVisible(DashboardWidget.streak);
        if (streakVisible) {
          children.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildProgressCard(tasksAsync)),
              const SizedBox(width: 16),
              Expanded(child: _buildStreakCard()),
            ],
          ));
          children.add(const SizedBox(height: 16));
          continue;
        }
        // Daily Goals alone
        children.add(buildWidget(widget));
        children.add(const SizedBox(height: 16));
      } else if (widget == DashboardWidget.streak) {
        // Skip if dailyGoals was shown (it would have included streak)
        if (isVisible(DashboardWidget.dailyGoals)) continue;
        // Streak alone
        children.add(buildWidget(widget));
        children.add(const SizedBox(height: 16));
      } else if (widget == DashboardWidget.notes) {
        // Check if deadlines is also visible
        final deadlinesVisible = isVisible(DashboardWidget.deadlines);
        if (deadlinesVisible) {
          children.add(Row(
            children: [
              Expanded(child: _buildNotesBento(notesAsync)),
              const SizedBox(width: 16),
              Expanded(child: _buildDeadlinesBento(tasksAsync)),
            ],
          ));
          children.add(const SizedBox(height: 16));
          continue;
        }
        // Notes alone
        children.add(buildWidget(widget));
        children.add(const SizedBox(height: 16));
      } else if (widget == DashboardWidget.deadlines) {
        // Skip if notes was shown (it would have included deadlines)
        if (isVisible(DashboardWidget.notes)) continue;
        // Deadlines alone
        children.add(buildWidget(widget));
        children.add(const SizedBox(height: 16));
      } else if (widget == DashboardWidget.overdueTasks) {
        // Overdue tasks widget handles its own visibility based on data
        children.add(buildWidget(widget));
        // No SizedBox here - the widget adds its own spacing
      } else {
        // Other widgets - full width
        children.add(buildWidget(widget));
        children.add(const SizedBox(height: 16));
      }
    }

    // Remove trailing SizedBox if present
    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }

    return Column(children: children);
  }

  Widget _buildAIInsightsCard(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final today = DateTime.now();
        final todayTasks = tasks.where((t) {
          final date = t.dueDate;
          return date != null && DateUtils.isSameDay(date, today);
        }).toList();

        final completedCount = todayTasks.where((t) => t.isCompleted).length;
        final totalCount = todayTasks.length;
        final overdueTasks = tasks.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          return t.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        }).length;
        final highPriorityTasks = tasks.where((t) {
          return !t.isCompleted && t.priority >= 2;
        }).length;
        final upcomingTitles = todayTasks
            .where((t) => !t.isCompleted)
            .take(3)
            .map((t) => t.title)
            .toList();

        return _AIInsightsContent(
          totalTasks: totalCount,
          completedTasks: completedCount,
          overdueTasks: overdueTasks,
          highPriorityTasks: highPriorityTasks,
          upcomingTaskTitles: upcomingTitles,
          scrollOffset: _scrollOffset,
          onInfoTap: () => _showInfoDialog('AI-powered insights based on your task patterns and productivity data.'),
        );
      },
      loading: () => const GlassCard(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildOverdueTasksWidget(
    AsyncValue<List<Task>> overdueTasksAsync,
    AsyncValue<List<Project>> projectsAsync,
  ) {
    return overdueTasksAsync.when(
      data: (overdueTasks) {
        if (overdueTasks.isEmpty) return const SizedBox();

        // Get projects map
        final projectsMap = <int, Project>{};
        projectsAsync.whenData((projects) {
          for (final p in projects) {
            projectsMap[p.id] = p;
          }
        });

        // Sort by due date (oldest first)
        final sortedTasks = List<Task>.from(overdueTasks)
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        return Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              color: AppColors.accentPink.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.accentPink,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overdue Tasks',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentPink,
                              ),
                            ),
                            Text(
                              '${overdueTasks.length} task${overdueTasks.length == 1 ? '' : 's'} need attention',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentPink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/tasks'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentPink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentPink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show up to 3 overdue tasks
                  ...sortedTasks.take(3).map((task) {
                    final daysOverdue = DateTime.now().difference(task.dueDate!).inDays;
                    final project = task.projectId != null ? projectsMap[task.projectId!] : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(task);
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentPink.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '$daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.accentPink.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    if (project != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Color(project.colorValue),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        project.name,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(project.colorValue).withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (overdueTasks.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${overdueTasks.length - 3} more overdue',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accentPink.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildProgressCard(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final today = DateTime.now();
        final todayTasks = tasks.where((t) {
          final date = t.dueDate;
          return date != null && DateUtils.isSameDay(date, today);
        }).toList();

        final completedCount = todayTasks.where((t) => t.isCompleted).length;
        final totalCount = todayTasks.length;
        final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

        return GlassCard(
          height: 180,
          padding: const EdgeInsets.all(20),
          // Parallax background effect
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.translate(
                  offset: Offset(0, _scrollOffset * 0.1),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 120,
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Daily Goals',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      _buildInfoTip('Track your daily task completion progress. Complete all tasks to keep your streak going!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount/$totalCount Done',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            color: AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
      },
      loading: () => const GlassCard(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStreakCard() {
    final streakAsync = ref.watch(taskStreakProvider);

    return streakAsync.when(
      data: (streak) => GlassCard(
        height: 180,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              streak > 0 ? Icons.local_fire_department_rounded : Icons.fireplace_rounded,
              color: streak > 0 ? AppColors.accentPink : AppColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Streak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 4),
                _buildInfoTip('Consecutive days completing all tasks. Keep it going!'),
              ],
            ),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: streak > 0 ? Colors.white : AppColors.textSecondary,
              ),
            ),
            Text(
              streak == 1 ? 'DAY' : 'DAYS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      loading: () => GlassCard(
        height: 180,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fireplace_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Streak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              '-',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              'DAYS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildNotesBento(AsyncValue<List<Note>> notesAsync) {
    return notesAsync
        .when(
          data: (notes) {
            final lastNote = notes.isNotEmpty
                ? notes.first.content
                : 'No thoughts yet...';
            return GestureDetector(
              onTap: () => context.push('/note_list'),
              child: GlassCard(
                height: 160,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            _buildInfoTip('Quick access to your notes. Tap to view all notes.'),
                          ],
                        ),
                        Text(
                          '${notes.length} Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      lastNote,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const GlassCard(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        )
        .animate()
        .fadeIn(delay: 500.ms)
        .slideY(begin: 0.1);
  }

  Widget _buildDeadlinesBento(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync
        .when(
          data: (tasks) {
            final now = DateTime.now();
            final upcomingTasks = tasks.where((t) {
              if (t.isCompleted || t.dueDate == null) return false;
              final daysUntilDue = t.dueDate!.difference(now).inDays;
              return daysUntilDue >= 0 && daysUntilDue <= 7;
            }).toList();

            return GestureDetector(
              onTap: () => context.push('/tasks'),
              child: GlassCard(
                height: 160,
                padding: const EdgeInsets.all(20),
                color: AppColors.accentBlue.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm_rounded,
                          color: AppColors.accentBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        _buildInfoTip('Tasks due within the next 7 days. Tap to view all tasks.'),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Due this week',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    Text(
                      '${upcomingTasks.length}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      upcomingTasks.length == 1 ? 'TASK' : 'TASKS',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const GlassCard(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        )
        .animate()
        .fadeIn(delay: 600.ms)
        .slideY(begin: 0.1);
  }

  Widget _buildProjectsBento(
    AsyncValue<List<Project>> projectsAsync,
    AsyncValue<List<Task>> tasksAsync,
  ) {
    return projectsAsync
        .when(
          data: (projects) {
            return GestureDetector(
              onTap: () => context.push('/projects'),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Active Projects',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildInfoTip('Your active projects. Tap to view all projects or tap a project to see details.'),
                          ],
                        ),
                        Text(
                          '${projects.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (projects.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No projects yet. Create one!',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: projects.take(5).length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return _ProjectBentoItem(project: project);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const GlassCard(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.1);
  }
}

class _ProjectBentoItem extends ConsumerWidget {
  final Project project;

  const _ProjectBentoItem({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskCountAsync = ref.watch(projectTaskCountProvider(project.id));

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(project.colorValue).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              project.emoji ?? '📁',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          taskCountAsync.when(
            data: (count) => Text(
              '$count tasks',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            loading: () => const SizedBox(height: 12),
            error: (_, __) => const SizedBox(height: 12),
          ),
        ],
      ),
    );
  }
}

class _AIInsightsContent extends ConsumerStatefulWidget {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int highPriorityTasks;
  final List<String> upcomingTaskTitles;
  final double scrollOffset;
  final VoidCallback onInfoTap;

  const _AIInsightsContent({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.highPriorityTasks,
    required this.upcomingTaskTitles,
    required this.scrollOffset,
    required this.onInfoTap,
  });

  @override
  ConsumerState<_AIInsightsContent> createState() => _AIInsightsContentState();
}

class _AIInsightsContentState extends ConsumerState<_AIInsightsContent> {
  String? _insight;
  List<String>? _suggestions;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAIInsights();
  }

  @override
  void didUpdateWidget(_AIInsightsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if task data changed significantly
    if (oldWidget.totalTasks != widget.totalTasks ||
        oldWidget.completedTasks != widget.completedTasks ||
        oldWidget.overdueTasks != widget.overdueTasks) {
      _loadAIInsights();
    }
  }

  Future<void> _loadAIInsights() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final geminiService = ref.read(geminiServiceProvider.notifier);

      // Fetch both insights in parallel
      final results = await Future.wait([
        geminiService.summarizeTasks(
          totalTasks: widget.totalTasks,
          completedTasks: widget.completedTasks,
          overdueTasks: widget.overdueTasks,
          highPriorityTasks: widget.highPriorityTasks,
          upcomingTaskTitles: widget.upcomingTaskTitles,
        ),
        geminiService.getProductivitySuggestions(
          streak: 0, // Will be updated when we have streak data
          weeklyCompleted: widget.completedTasks,
          weeklyTotal: widget.totalTasks,
          completionRate: widget.totalTasks > 0
              ? widget.completedTasks / widget.totalTasks
              : 0.0,
        ),
      ]);

      if (mounted) {
        setState(() {
          _insight = results[0] as String;
          _suggestions = results[1] as List<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      color: AppColors.accentPink.withValues(alpha: 0.05),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Transform.translate(
              offset: Offset(0, widget.scrollOffset * 0.05),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 80,
                color: AppColors.accentPink.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.accentPink,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Insights',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onInfoTap,
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: _loadAIInsights,
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentPink,
                      ),
                    ),
                  ),
                )
              else if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Could not load insights',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else ...[
                // Main insight
                if (_insight != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.accentPink.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _insight!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Suggestions
                if (_suggestions != null && _suggestions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions!.map((suggestion) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1);
  }
}

/// Countdown Timer Widget
class CountdownTimerWidget extends StatefulWidget {
  const CountdownTimerWidget({super.key});

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  int _hours = 0;
  int _minutes = 25;
  int _seconds = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  final _liveActivityService = LiveActivityService();
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _liveActivityService.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liveActivityService.dispose();
    super.dispose();
  }

  void _startTimer() async {
    if (_remainingSeconds == 0) {
      _remainingSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    }
    if (_remainingSeconds <= 0) return;

    // Calculate end time
    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    setState(() => _isRunning = true);

    // Start Live Activity on iOS
    if (Platform.isIOS) {
      await _liveActivityService.startTimerActivity(
        totalDuration: Duration(seconds: (_hours * 3600) + (_minutes * 60) + _seconds),
        endTime: _endTime!,
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _isRunning = false);
        // End Live Activity
        await _liveActivityService.endTimerActivity();
        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timer completed!'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);
    // Pause Live Activity
    await _liveActivityService.pauseTimerActivity(
      remainingSeconds: _remainingSeconds,
    );
  }

  void _resetTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
    // End Live Activity
    await _liveActivityService.endTimerActivity();
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => _TimerPickerSheet(
        initialHours: _hours,
        initialMinutes: _minutes,
        initialSeconds: _seconds,
        onConfirm: (h, m, s) {
          setState(() {
            _hours = h;
            _minutes = m;
            _seconds = s;
            _remainingSeconds = 0; // Reset when time changes
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = _remainingSeconds > 0 ? _remainingSeconds : (_hours * 3600) + (_minutes * 60) + _seconds;
    final progress = (_hours * 3600 + _minutes * 60 + _seconds) > 0
        ? 1 - (_remainingSeconds / ((_hours * 3600) + (_minutes * 60) + _seconds).clamp(1, double.infinity))
        : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      color: AppColors.accentBlue.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_rounded,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Focus Timer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isRunning ? null : _showTimePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Set Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Timer Display
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress Ring
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _isRunning ? progress : 0,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  ),
                ),
                // Time Display
                GestureDetector(
                  onTap: _isRunning ? null : _showTimePicker,
                  child: Text(
                    _formatTime(displaySeconds),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              GestureDetector(
                onTap: _resetTimer,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Play/Pause Button
              GestureDetector(
                onTap: _isRunning ? _pauseTimer : _startTimer,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.primary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Quick Preset Button
              GestureDetector(
                onTap: () {
                  if (!_isRunning) {
                    setState(() {
                      _hours = 0;
                      _minutes = 25;
                      _seconds = 0;
                      _remainingSeconds = 0;
                    });
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '25m',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }
}

/// Timer Picker Sheet
class _TimerPickerSheet extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final int initialSeconds;
  final Function(int hours, int minutes, int seconds) onConfirm;

  const _TimerPickerSheet({
    required this.initialHours,
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onConfirm,
  });

  @override
  State<_TimerPickerSheet> createState() => _TimerPickerSheetState();
}

class _TimerPickerSheetState extends State<_TimerPickerSheet> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set Timer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _buildNumberPicker(
                value: _hours,
                maxValue: 23,
                label: 'Hours',
                onChanged: (v) => setState(() => _hours = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 32, color: Colors.white54)),
              ),
              // Minutes
              _buildNumberPicker(
                value: _minutes,
                maxValue: 59,
                label: 'Minutes',
                onChanged: (v) => setState(() => _minutes = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 32, color: Colors.white54)),
              ),
              // Seconds
              _buildNumberPicker(
                value: _seconds,
                maxValue: 59,
                label: 'Seconds',
                onChanged: (v) => setState(() => _seconds = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton('5m', 0, 5, 0),
              _buildPresetButton('15m', 0, 15, 0),
              _buildPresetButton('25m', 0, 25, 0),
              _buildPresetButton('45m', 0, 45, 0),
              _buildPresetButton('1h', 1, 0, 0),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_hours, _minutes, _seconds);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int maxValue,
    required String label,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(value < maxValue ? value + 1 : 0),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54),
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(value > 0 ? value - 1 : maxValue),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int hours, int minutes, int seconds) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hours = hours;
          _minutes = minutes;
          _seconds = seconds;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Dashboard Settings Sheet
class _DashboardSettingsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _DashboardSettingsSheet({required this.ref});

  @override
  ConsumerState<_DashboardSettingsSheet> createState() => _DashboardSettingsSheetState();
}

class _DashboardSettingsSheetState extends ConsumerState<_DashboardSettingsSheet> {
  IconData _getWidgetIcon(DashboardWidget widget) {
    switch (widget) {
      case DashboardWidget.dailyGoals:
        return Icons.trending_up_rounded;
      case DashboardWidget.streak:
        return Icons.local_fire_department_rounded;
      case DashboardWidget.overdueTasks:
        return Icons.warning_amber_rounded;
      case DashboardWidget.notes:
        return Icons.edit_note_rounded;
      case DashboardWidget.deadlines:
        return Icons.alarm_rounded;
      case DashboardWidget.aiInsights:
        return Icons.auto_awesome_rounded;
      case DashboardWidget.focusTimer:
        return Icons.timer_rounded;
      case DashboardWidget.projects:
        return Icons.folder_rounded;
    }
  }

  Color _getWidgetColor(DashboardWidget widget) {
    switch (widget) {
      case DashboardWidget.dailyGoals:
        return AppColors.primary;
      case DashboardWidget.streak:
        return AppColors.accentPink;
      case DashboardWidget.overdueTasks:
        return AppColors.accentPink;
      case DashboardWidget.notes:
        return AppColors.secondary;
      case DashboardWidget.deadlines:
        return AppColors.accentBlue;
      case DashboardWidget.aiInsights:
        return AppColors.accentPink;
      case DashboardWidget.focusTimer:
        return AppColors.accentBlue;
      case DashboardWidget.projects:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(dashboardSettingsControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return GlassCard(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: settingsAsync.when(
            data: (settings) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(dashboardSettingsControllerProvider.notifier).resetToDefaults();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag to reorder. Tap to show/hide widgets.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    itemCount: settings.widgetOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      ref.read(dashboardSettingsControllerProvider.notifier)
                          .reorderWidgets(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final widget = settings.widgetOrder[index];
                      final isHidden = settings.hiddenWidgets.contains(widget);

                      return Container(
                        key: Key('widget_${widget.name}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (Platform.isIOS) {
                              HapticFeedback.lightImpact();
                            }
                            ref.read(dashboardSettingsControllerProvider.notifier)
                                .toggleWidgetVisibility(widget);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isHidden
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHidden
                                    ? Colors.transparent
                                    : _getWidgetColor(widget).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Drag handle
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: Colors.white.withValues(alpha: 0.4),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Widget icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isHidden
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : _getWidgetColor(widget).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getWidgetIcon(widget),
                                    color: isHidden
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : _getWidgetColor(widget),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Widget name
                                Expanded(
                                  child: Text(
                                    widget.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isHidden
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                // Visibility toggle
                                Icon(
                                  isHidden
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: isHidden
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : AppColors.accentGreen,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        );
      },
    );
  }
}
