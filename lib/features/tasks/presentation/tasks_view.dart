import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/features/tasks/presentation/widgets/task_card.dart';
import 'package:mindfree/features/projects/presentation/projects_controller.dart';
import 'package:mindfree/features/home/presentation/home_screen.dart' show taskEmojis;
import 'package:mindfree/data/models/task.dart';
import 'package:mindfree/data/models/project.dart';

// Sort options enum
enum TaskSortOption { date, priority, manual }

class TasksView extends ConsumerStatefulWidget {
  const TasksView({super.key});

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showOverdueTasks = false;
  bool _hideCompleted = false;
  TaskSortOption _sortBy = TaskSortOption.priority;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
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
                    'Tasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Filter options button
                  GestureDetector(
                    onTap: _showFilterOptions,
                    child: const GlassCard(
                      borderRadius: 12,
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sort & Filter chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Sort by dropdown
                    _buildSortChip(),
                    const SizedBox(width: 8),
                    // Hide completed toggle
                    GestureDetector(
                      onTap: () => setState(() => _hideCompleted = !_hideCompleted),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _hideCompleted
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hideCompleted ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hideCompleted ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 14,
                              color: _hideCompleted ? AppColors.primary : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hide done',
                              style: TextStyle(
                                fontSize: 12,
                                color: _hideCompleted ? AppColors.primary : Colors.white54,
                                fontWeight: _hideCompleted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                DateFormat('EEEE, d MMMM y').format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 20),

              // Horizontal Date Selector
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14, // 2 weeks
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index - 2));
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 12),
                        child: GlassCard(
                          borderRadius: 20,
                          color: isSelected ? AppColors.primary : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(date).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Task List
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    // Watch projects for mapping
                    final projectsAsync = ref.watch(projectsControllerProvider);
                    final projectsMap = <int, Project>{};
                    projectsAsync.whenData((projects) {
                      for (final p in projects) {
                        projectsMap[p.id] = p;
                      }
                    });

                    // Get overdue tasks (from previous days, not completed)
                    final today = DateTime.now();
                    final overdueTasks = tasks.where((t) {
                      if (t.isCompleted || t.dueDate == null) return false;
                      final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                      final todayDate = DateTime(today.year, today.month, today.day);
                      return taskDate.isBefore(todayDate);
                    }).toList();

                    // Sort overdue by date (oldest first)
                    overdueTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

                    var dayTasks = tasks.where((t) {
                      if (t.dueDate == null) return false;
                      return DateUtils.isSameDay(t.dueDate!, _selectedDate);
                    }).toList();

                    // Apply hide completed filter
                    if (_hideCompleted) {
                      dayTasks = dayTasks.where((t) => !t.isCompleted).toList();
                    }

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      dayTasks = dayTasks.where((t) {
                        return t.title
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            (t.description
                                    ?.toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ??
                                false);
                      }).toList();
                    }

                    // Apply sorting
                    _sortTasks(dayTasks);

                    final hasOverdue = overdueTasks.isNotEmpty && DateUtils.isSameDay(_selectedDate, today);

                    if (dayTasks.isEmpty && !hasOverdue) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching tasks'
                                  : 'No tasks for this day',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group tasks by project
                    final groupedTasks = groupBy<Task, int?>(dayTasks, (t) => t.projectId);
                    final sortedGroupKeys = groupedTasks.keys.toList()
                      ..sort((a, b) {
                        if (a == null) return 1; // null projects at end
                        if (b == null) return -1;
                        return a.compareTo(b);
                      });

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(tasksControllerProvider);
                      },
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Overdue Tasks Dropdown
                          if (hasOverdue) ...[
                            GestureDetector(
                              onTap: () => setState(() => _showOverdueTasks = !_showOverdueTasks),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: AppColors.accentPink.withValues(alpha: 0.1),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.accentPink,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${overdueTasks.length} Overdue Task${overdueTasks.length == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: AppColors.accentPink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _showOverdueTasks
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.accentPink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showOverdueTasks) ...[
                              const SizedBox(height: 12),
                              ...overdueTasks.map((task) => _buildOverdueTask(task, projectsMap)),
                            ],
                            const SizedBox(height: 16),
                          ],
                          // Tasks grouped by project
                          ...sortedGroupKeys.expand((projectId) {
                            final projectTasks = groupedTasks[projectId]!;
                            final project = projectId != null ? projectsMap[projectId] : null;
                            return [
                              // Project section header
                              if (sortedGroupKeys.length > 1 || projectId != null)
                                _buildProjectSectionHeader(project),
                              // Tasks in this project
                              ...projectTasks.map((task) => _buildDismissibleTask(
                                task,
                                projectsMap,
                                showProjectBadge: sortedGroupKeys.length == 1,
                              )),
                            ];
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleTask(Task task, Map<int, Project> projectsMap, {bool showProjectBadge = true}) {
    final project = task.projectId != null ? projectsMap[task.projectId!] : null;
    return Dismissible(
      key: Key('task_${task.id}'),
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
          return false; // Don't dismiss, just show edit dialog
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
        onLongPress: () {
          if (Platform.isIOS) {
            HapticFeedback.mediumImpact();
          }
          _showTaskOptions(task);
        },
        onSubtaskToggle: (index) => ref
            .read(tasksControllerProvider.notifier)
            .toggleSubtask(task, index),
        projectName: showProjectBadge ? project?.name : null,
        projectColor: showProjectBadge && project != null ? Color(project.colorValue) : null,
      ),
    );
  }

  Widget _buildOverdueTask(Task task, Map<int, Project> projectsMap) {
    final daysOverdue = DateTime.now().difference(task.dueDate!).inDays;
    final project = task.projectId != null ? projectsMap[task.projectId!] : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        color: AppColors.accentPink.withValues(alpha: 0.05),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref
                  .read(tasksControllerProvider.notifier)
                  .toggleTaskCompletion(task),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPink.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.accentPink.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('MMM d').format(task.dueDate!)} • $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accentPink.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'complete':
                    ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(task);
                    break;
                  case 'reschedule':
                    _rescheduleTask(task);
                    break;
                  case 'delete':
                    _confirmDelete(task);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 20),
                      SizedBox(width: 12),
                      Text('Complete', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reschedule',
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text('Reschedule to Today', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppColors.accentPink, size: 20),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: AppColors.accentPink)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _rescheduleTask(Task task) {
    task.dueDate = DateTime.now();
    ref.read(tasksControllerProvider.notifier).updateTask(task);
    AppToast.show(
      context,
      message: 'Task rescheduled to today',
      type: ToastType.success,
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
        },
      ),
    );
  }

  // Sort tasks based on selected option
  void _sortTasks(List<Task> tasks) {
    switch (_sortBy) {
      case TaskSortOption.date:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          final aDate = a.dueDate ?? DateTime(2099);
          final bDate = b.dueDate ?? DateTime(2099);
          return aDate.compareTo(bDate);
        });
        break;
      case TaskSortOption.priority:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.priority.compareTo(a.priority);
        });
        break;
      case TaskSortOption.manual:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return a.sortOrder.compareTo(b.sortOrder);
        });
        break;
    }
  }

  // Build sort chip with dropdown
  Widget _buildSortChip() {
    final sortLabels = {
      TaskSortOption.date: 'Date',
      TaskSortOption.priority: 'Priority',
      TaskSortOption.manual: 'Manual',
    };
    final sortIcons = {
      TaskSortOption.date: Icons.calendar_today_rounded,
      TaskSortOption.priority: Icons.flag_rounded,
      TaskSortOption.manual: Icons.drag_handle_rounded,
    };

    return PopupMenuButton<TaskSortOption>(
      onSelected: (option) => setState(() => _sortBy = option),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sortIcons[_sortBy], size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              'Sort: ${sortLabels[_sortBy]}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
          ],
        ),
      ),
      itemBuilder: (context) => TaskSortOption.values.map((option) {
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              Icon(
                sortIcons[option],
                size: 18,
                color: _sortBy == option ? AppColors.primary : Colors.white54,
              ),
              const SizedBox(width: 12),
              Text(
                sortLabels[option]!,
                style: TextStyle(
                  color: _sortBy == option ? AppColors.primary : Colors.white,
                  fontWeight: _sortBy == option ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Build project section header
  Widget _buildProjectSectionHeader(Project? project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: project != null
            ? Color(project.colorValue).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: project != null
              ? Color(project.colorValue).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: project != null ? Color(project.colorValue) : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (project?.emoji != null) ...[
            Text(project!.emoji!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              project?.name ?? 'No Project',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: project != null ? Color(project.colorValue) : Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show filter options bottom sheet
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskSortOption.values.map((option) {
                final isSelected = _sortBy == option;
                final labels = {
                  TaskSortOption.date: 'Date',
                  TaskSortOption.priority: 'Priority',
                  TaskSortOption.manual: 'Manual',
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sortBy = option),
                    child: Container(
                      margin: EdgeInsets.only(right: option != TaskSortOption.manual ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labels[option]!,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filters',
              style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _hideCompleted,
              onChanged: (value) => setState(() => _hideCompleted = value),
              title: const Text('Hide completed tasks', style: TextStyle(color: Colors.white)),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Edit Task Sheet Widget
class EditTaskSheet extends ConsumerStatefulWidget {
  final Task task;
  final Function(Task) onSave;

  const EditTaskSheet({
    super.key,
    required this.task,
    required this.onSave,
  });

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final _subtaskController = TextEditingController();
  final _tagController = TextEditingController();
  late List<SubtaskItem> _subtasks;
  late List<String> _selectedTags;
  late DateTime _dueDate;
  DateTime? _endDate;
  DateTime? _reminderTime;
  late int _priority;
  String? _selectedEmoji;

  // Common tags for quick selection
  static const List<String> _commonTags = [
    'work', 'personal', 'urgent', 'meeting', 'call', 'email',
    'shopping', 'health', 'finance', 'travel', 'study', 'home',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description ?? '');
    _subtasks = widget.task.subtaskItems.toList();
    _selectedTags = widget.task.tags?.toList() ?? [];
    _dueDate = widget.task.dueDate ?? DateTime.now();
    _endDate = widget.task.endDate;
    _reminderTime = widget.task.reminderTime;
    _priority = widget.task.priority;
    _selectedEmoji = widget.task.emoji;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _tagController.dispose();
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
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEmojiPicker(),
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
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                  'Description',
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add some details...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority Selection
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
                const SizedBox(height: 16),

                // Subtasks Checklist
                const Text(
                  'Subtasks',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a subtask',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addSubtask,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (_subtasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._subtasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final subtask = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        leading: GestureDetector(
                          onTap: () {
                            setState(() {
                              _subtasks[index] = subtask.copyWith(
                                isCompleted: !subtask.isCompleted,
                              );
                            });
                          },
                          child: Icon(
                            subtask.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: subtask.isCompleted
                                ? AppColors.accentGreen
                                : Colors.white38,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          subtask.title,
                          style: TextStyle(
                            color: subtask.isCompleted
                                ? Colors.white38
                                : Colors.white,
                            decoration: subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            setState(() => _subtasks.removeAt(index));
                          },
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),

                // Tags Section
                const Text(
                  'Tags',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Selected tags
                if (_selectedTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTags.remove(tag)),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                // Add new tag
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a tag',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addTag,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick tag selection
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonTags.where((tag) => !_selectedTags.contains(tag)).take(8).map((tag) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTags.add(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Date Range
                const Text(
                  'Date Range',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _dueDate = date);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(fontSize: 10, color: Colors.white38),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd').format(_dueDate),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white24),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _dueDate,
                            firstDate: _dueDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(fontSize: 10, color: Colors.white38),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? DateFormat('MMM dd').format(_endDate!)
                                    : 'Optional',
                                style: TextStyle(
                                  color: _endDate != null ? Colors.white : Colors.white24,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
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

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(SubtaskItem(title: _subtaskController.text));
        _subtaskController.clear();
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
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

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final updatedTask = widget.task
        ..title = _titleController.text.trim()
        ..description = _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null
        ..dueDate = _dueDate
        ..endDate = _endDate
        ..reminderTime = _reminderTime
        ..priority = _priority
        ..emoji = _selectedEmoji
        ..tags = _selectedTags.isNotEmpty ? _selectedTags : null;

      updatedTask.setSubtaskItems(_subtasks);

      widget.onSave(updatedTask);
      Navigator.pop(context);

      AppToast.show(
        context,
        message: 'Task updated successfully',
        type: ToastType.success,
      );
    }
  }
}
