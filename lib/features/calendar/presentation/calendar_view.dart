import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/features/tasks/presentation/widgets/task_card.dart';
import 'package:mindfree/features/tasks/presentation/tasks_view.dart' show EditTaskSheet;
import 'package:mindfree/data/models/task.dart';
import 'package:intl/intl.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Map<DateTime, List<Task>> _getTasksForCalendar(List<Task> tasks) {
    final Map<DateTime, List<Task>> taskMap = {};

    for (final task in tasks) {
      if (task.dueDate != null) {
        final date = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (taskMap[date] == null) {
          taskMap[date] = [];
        }
        taskMap[date]!.add(task);
      }
    }

    return taskMap;
  }

  List<Task> _getEventsForDay(DateTime day, Map<DateTime, List<Task>> taskMap) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return taskMap[normalizedDay] ?? [];
  }

  String _getFormatButtonText() {
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return 'Month';
      case CalendarFormat.twoWeeks:
        return '2 Weeks';
      case CalendarFormat.week:
        return 'Week';
    }
  }

  void _cycleCalendarFormat() {
    setState(() {
      switch (_calendarFormat) {
        case CalendarFormat.month:
          _calendarFormat = CalendarFormat.twoWeeks;
          break;
        case CalendarFormat.twoWeeks:
          _calendarFormat = CalendarFormat.week;
          break;
        case CalendarFormat.week:
          _calendarFormat = CalendarFormat.month;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showAddMenu(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: const GlassCard(
                      borderRadius: 12,
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'Calendar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // View format toggle button
                  GestureDetector(
                    onTap: _cycleCalendarFormat,
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _calendarFormat == CalendarFormat.month
                                ? Icons.calendar_month_rounded
                                : _calendarFormat == CalendarFormat.twoWeeks
                                    ? Icons.calendar_view_week_rounded
                                    : Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getFormatButtonText(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Glass Calendar Widget
              tasksAsync.when(
                data: (tasks) {
                  final taskMap = _getTasksForCalendar(tasks);

                  return GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<Task>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                        CalendarFormat.twoWeeks: '2 Weeks',
                        CalendarFormat.week: 'Week',
                      },
                      eventLoader: (day) => _getEventsForDay(day, taskMap),
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onDayLongPressed: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showAddMenu(context, selectedDate: selectedDay);
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;

                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final dateNormalized = DateTime(date.year, date.month, date.day);

                          final completedCount =
                              events.where((t) => t.isCompleted).length;
                          final incompleteCount = events.length - completedCount;
                          final hasIncomplete = incompleteCount > 0;
                          final allCompleted = completedCount == events.length;

                          // Check if this is an overdue day (past date with incomplete tasks)
                          final isOverdue = dateNormalized.isBefore(today) && hasIncomplete;

                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show overdue indicator (pulsing red dot)
                                if (isOverdue)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPink,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accentPink.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  )
                                // Show incomplete dot for today/future
                                else if (hasIncomplete)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                // Show green dot if all completed
                                if (allCompleted)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                // Show high priority indicator
                                if (events.any((t) => t.priority == 2 && !t.isCompleted) && !isOverdue)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentPink,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(
                          color: AppColors.accentPink,
                        ),
                        outsideTextStyle:
                            const TextStyle(color: Colors.white24),
                        markersMaxCount: 3,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        formatButtonDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          color: AppColors.primary,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Tasks on ${DateFormat('MMMM d').format(_selectedDay!)}'
                        : 'Select a day',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedDay != null)
                    GestureDetector(
                      onTap: () => _showAddMenu(context, selectedDate: _selectedDay),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Tasks List for selected day with swipe actions
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    final dayTasks = tasks
                        .where(
                          (t) =>
                              t.dueDate != null &&
                              isSameDay(t.dueDate!, _selectedDay),
                        )
                        .toList();

                    // Sort by priority (high first) then by completion
                    dayTasks.sort((a, b) {
                      if (a.isCompleted != b.isCompleted) {
                        return a.isCompleted ? 1 : -1;
                      }
                      return b.priority.compareTo(a.priority);
                    });

                    if (dayTasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tasks for this day',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _showAddMenu(
                                context,
                                selectedDate: _selectedDay,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Add Task or Note',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(tasksControllerProvider);
                      },
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: dayTasks.length,
                        itemBuilder: (context, index) {
                          return _buildDismissibleTask(dayTasks[index]);
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleTask(Task task) {
    return Dismissible(
      key: Key('calendar_task_${task.id}'),
      direction: DismissDirection.horizontal,
      // Edit background (swipe right)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.edit_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
      // Delete background (swipe left)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.accentPink.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.accentPink,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Edit
          _showEditTaskDialog(task);
          return false;
        } else {
          // Swipe left - Delete
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Delete Task',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Are you sure you want to delete "${task.title}"?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.accentPink),
                  ),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        final deletedTask = task;
        ref.read(tasksControllerProvider.notifier).deleteTask(task.id);

        AppToast.show(
          context,
          message: 'Deleted "${deletedTask.title}"',
          type: ToastType.info,
          onUndo: () {
            ref.read(tasksControllerProvider.notifier).addTask(
                  projectId: deletedTask.projectId,
                  title: deletedTask.title,
                  description: deletedTask.description,
                  dueDate: deletedTask.dueDate,
                  endDate: deletedTask.endDate,
                  reminderTime: deletedTask.reminderTime,
                  priority: deletedTask.priority,
                  emoji: deletedTask.emoji,
                  subtasks: deletedTask.subtasks,
                );
          },
        );
      },
      child: TaskCard(
        task: task,
        onTap: () => ref
            .read(tasksControllerProvider.notifier)
            .toggleTaskCompletion(task),
        onLongPress: () => _showTaskOptions(task),
        onSubtaskToggle: (index) => ref
            .read(tasksControllerProvider.notifier)
            .toggleSubtask(task, index),
      ),
    );
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (sheetContext) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                task.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                color: AppColors.accentGreen,
              ),
              title: Text(
                task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                ref
                    .read(tasksControllerProvider.notifier)
                    .toggleTaskCompletion(task);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Edit Task',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditTaskDialog(task);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.accentPink,
              ),
              title: const Text(
                'Delete Task',
                style: TextStyle(color: AppColors.accentPink),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(task);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Task',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final deletedTask = task;
              ref.read(tasksControllerProvider.notifier).deleteTask(task.id);

              AppToast.show(
                this.context,
                message: 'Deleted "${deletedTask.title}"',
                type: ToastType.info,
                onUndo: () {
                  ref.read(tasksControllerProvider.notifier).addTask(
                        projectId: deletedTask.projectId,
                        title: deletedTask.title,
                        description: deletedTask.description,
                        dueDate: deletedTask.dueDate,
                        endDate: deletedTask.endDate,
                        reminderTime: deletedTask.reminderTime,
                        priority: deletedTask.priority,
                        emoji: deletedTask.emoji,
                        subtasks: deletedTask.subtasks,
                      );
                },
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentPink),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => EditTaskSheet(
        task: task,
        onSave: (updatedTask) {
          ref.read(tasksControllerProvider.notifier).updateTask(updatedTask);
          AppToast.show(
            this.context,
            message: 'Task updated successfully',
            type: ToastType.success,
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context, {DateTime? selectedDate}) {
    final dateToUse = selectedDate ?? _selectedDay ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to ${DateFormat('MMMM d').format(dateToUse)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _showAddTaskSheet(dateToUse);
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.secondary,
                ),
              ),
              title: const Text(
                'New Task',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Add a task for this day',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                this.context.push('/note_editor');
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_add_rounded,
                  color: AppColors.accentPink,
                ),
              ),
              title: const Text(
                'New Note',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Capture your thoughts',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet(DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CalendarAddTaskSheet(
        initialDate: selectedDate,
        onTaskCreated: () {
          AppToast.show(
            this.context,
            message: 'Task created successfully',
            type: ToastType.success,
          );
        },
      ),
    );
  }
}

/// Add Task Sheet specifically for Calendar with pre-selected date
class CalendarAddTaskSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final VoidCallback? onTaskCreated;

  const CalendarAddTaskSheet({
    super.key,
    required this.initialDate,
    this.onTaskCreated,
  });

  @override
  ConsumerState<CalendarAddTaskSheet> createState() =>
      _CalendarAddTaskSheetState();
}

class _CalendarAddTaskSheetState extends ConsumerState<CalendarAddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late DateTime _dueDate;
  int _priority = 1;
  String? _selectedEmoji;

  static const Map<int, String> priorityLabels = {
    0: 'Low',
    1: 'Medium',
    2: 'High',
  };

  static const Map<int, Color> priorityColors = {
    0: AppColors.accentBlue,
    1: AppColors.secondary,
    2: AppColors.accentPink,
  };

  static const List<String> taskEmojis = [
    '📝', '🎯', '💼', '📞', '✉️', '🔔',
    '⭐', '🚀', '💡', '🔧', '📊', '🎨',
  ];

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Task',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showEmojiPicker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedEmoji ?? '📝',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_dueDate),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Task Name *',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorStyle: const TextStyle(color: AppColors.accentPink),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description (Optional)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add some details...',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [0, 1, 2].map((priority) {
                    final isSelected = _priority == priority;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = priority),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: priority < 2 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? priorityColors[priority]!.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? priorityColors[priority]!
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              priorityLabels[priority]!,
                              style: TextStyle(
                                color: isSelected
                                    ? priorityColors[priority]
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _createTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Task',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose an Emoji',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: taskEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedEmoji == emoji
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      ref.read(tasksControllerProvider.notifier).addTask(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            dueDate: _dueDate,
            priority: _priority,
            emoji: _selectedEmoji,
          );

      Navigator.pop(context);
      widget.onTaskCreated?.call();
    }
  }
}
