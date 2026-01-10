import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/data/repositories/project_repository.dart';
import 'package:mindfree/features/projects/presentation/projects_controller.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/features/tasks/presentation/widgets/task_card.dart';
import 'package:mindfree/features/tasks/presentation/tasks_view.dart' show EditTaskSheet;
import 'package:mindfree/features/notes/presentation/notes_controller.dart';
import 'package:mindfree/features/notes/presentation/note_editor_view.dart';
import 'package:mindfree/data/services/gemini_service.dart';
import 'package:mindfree/core/widgets/delete_dialog.dart';
import 'package:mindfree/features/home/presentation/home_screen.dart' show projectColors, projectEmojis, DetailedAddTaskSheet;
import 'package:mindfree/data/models/project.dart';
import 'package:mindfree/data/models/task.dart';

class ProjectDetailView extends ConsumerStatefulWidget {
  final int projectId;
  const ProjectDetailView({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailView> createState() => _ProjectDetailViewState();
}

// Sort options enum for project tasks
enum ProjectTaskSortOption { date, priority, manual }

class _ProjectDetailViewState extends ConsumerState<ProjectDetailView> {
  bool _isSummarizing = false;
  bool _hideCompleted = false;
  ProjectTaskSortOption _sortBy = ProjectTaskSortOption.priority;

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref
        .watch(projectRepositoryProvider)
        .getProjectById(widget.projectId);
    final tasksAsync = ref.watch(projectTasksProvider(widget.projectId));
    final notesAsync = ref.watch(notesByParentProvider(0, widget.projectId));

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: FutureBuilder(
              future: projectAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final project = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
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
                          Expanded(
                            child: Text(
                              project.name,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _showProjectMenu(context, project),
                                child: const GlassCard(
                                  borderRadius: 12,
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.more_horiz,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _isSummarizing
                                    ? null
                                    : () => _showAISummary(project),
                                child: GlassCard(
                                  borderRadius: 12,
                                  padding: const EdgeInsets.all(8),
                                  child: _isSummarizing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.secondary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.auto_awesome,
                                          color: AppColors.secondary,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Tabs or Sections
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TabBar(
                                  tabs: const [
                                    Tab(text: 'Tasks'),
                                    Tab(text: 'Notes'),
                                  ],
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  indicatorPadding: const EdgeInsets.all(4),
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: Colors.white54,
                                  dividerColor: Colors.transparent,
                                  splashBorderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TabBarView(
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    // Tasks List with sorting and filtering
                                    tasksAsync.when(
                                      data: (tasks) {
                                        // Apply hide completed filter
                                        var filteredTasks = _hideCompleted
                                            ? tasks.where((t) => !t.isCompleted).toList()
                                            : List<Task>.from(tasks);

                                        // Apply sorting
                                        _sortTasks(filteredTasks);

                                        if (tasks.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.task_alt_rounded,
                                                  size: 48,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'No tasks yet',
                                                  style: TextStyle(
                                                      color: Colors.white54),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Column(
                                          children: [
                                            // Sort & Filter controls
                                            _buildTaskFilterControls(),
                                            const SizedBox(height: 12),
                                            // Task list
                                            Expanded(
                                              child: filteredTasks.isEmpty
                                                  ? Center(
                                                      child: Text(
                                                        _hideCompleted
                                                            ? 'All tasks completed!'
                                                            : 'No tasks yet',
                                                        style: const TextStyle(
                                                            color: Colors.white54),
                                                      ),
                                                    )
                                                  : RefreshIndicator(
                                                      onRefresh: () async {
                                                        ref.invalidate(projectTasksProvider(
                                                            widget.projectId));
                                                      },
                                                      child: _sortBy == ProjectTaskSortOption.manual
                                                          ? ReorderableListView.builder(
                                                              itemCount: filteredTasks.length,
                                                              onReorder: (oldIndex, newIndex) {
                                                                _onReorderTasks(filteredTasks, oldIndex, newIndex);
                                                              },
                                                              proxyDecorator: (child, index, animation) {
                                                                return Material(
                                                                  color: Colors.transparent,
                                                                  elevation: 4,
                                                                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                                                                  child: child,
                                                                );
                                                              },
                                                              itemBuilder: (context, index) =>
                                                                  _buildReorderableTask(filteredTasks[index], index),
                                                            )
                                                          : ListView.builder(
                                                              itemCount: filteredTasks.length,
                                                              itemBuilder: (context, index) =>
                                                                  _buildDismissibleTask(filteredTasks[index]),
                                                            ),
                                                    ),
                                            ),
                                          ],
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (err, _) =>
                                          Center(child: Text('Error: $err')),
                                    ),
                                    // Notes List
                                    notesAsync.when(
                                      data: (notes) {
                                        if (notes.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.note_alt_outlined,
                                                  size: 48,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'No notes yet',
                                                  style: TextStyle(
                                                      color: Colors.white54),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return RefreshIndicator(
                                          onRefresh: () async {
                                            ref.invalidate(notesByParentProvider(
                                                0, widget.projectId));
                                          },
                                          child: ListView.builder(
                                            itemCount: notes.length,
                                            itemBuilder: (context, index) =>
                                                GestureDetector(
                                              onTap: () => context.push(
                                                '/note_editor',
                                                extra: notes[index],
                                              ),
                                              child: GlassCard(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Text(
                                                  notes[index].content,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (err, _) =>
                                          Center(child: Text('Error: $err')),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAISummary(Project project) async {
    setState(() => _isSummarizing = true);

    try {
      final summary = await ref
          .read(geminiServiceProvider.notifier)
          .summarize(project.name + (project.description ?? ""));

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'AI Summary',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            summary,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  // Sort tasks based on selected option
  void _sortTasks(List<Task> tasks) {
    switch (_sortBy) {
      case ProjectTaskSortOption.date:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          final aDate = a.dueDate ?? DateTime(2099);
          final bDate = b.dueDate ?? DateTime(2099);
          return aDate.compareTo(bDate);
        });
        break;
      case ProjectTaskSortOption.priority:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.priority.compareTo(a.priority);
        });
        break;
      case ProjectTaskSortOption.manual:
        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return a.sortOrder.compareTo(b.sortOrder);
        });
        break;
    }
  }

  // Build filter controls row
  Widget _buildTaskFilterControls() {
    final sortLabels = {
      ProjectTaskSortOption.date: 'Date',
      ProjectTaskSortOption.priority: 'Priority',
      ProjectTaskSortOption.manual: 'Manual',
    };
    final sortIcons = {
      ProjectTaskSortOption.date: Icons.calendar_today_rounded,
      ProjectTaskSortOption.priority: Icons.flag_rounded,
      ProjectTaskSortOption.manual: Icons.drag_handle_rounded,
    };

    return Row(
      children: [
        // Sort dropdown
        PopupMenuButton<ProjectTaskSortOption>(
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
          itemBuilder: (context) => ProjectTaskSortOption.values.map((option) {
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
        ),
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
    );
  }

  // Build task with drag handle for reordering
  Widget _buildReorderableTask(Task task, int index) {
    return Container(
      key: Key('reorderable_task_${task.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
          ),
          // Task card
          Expanded(
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
              onSubtaskToggle: (subtaskIndex) => ref
                  .read(tasksControllerProvider.notifier)
                  .toggleSubtask(task, subtaskIndex),
            ),
          ),
        ],
      ),
    );
  }

  // Handle reorder for tasks
  void _onReorderTasks(List<Task> tasks, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);

    // Update sort orders for each task in the list
    for (int i = 0; i < tasks.length; i++) {
      tasks[i].sortOrder = i;
    }
    ref.read(tasksControllerProvider.notifier).updateSortOrders(tasks);
  }

  void _showProjectMenu(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text(
                'Edit Project',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditProjectDialog(project);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.accentPink,
              ),
              title: const Text(
                'Delete Project',
                style: TextStyle(color: AppColors.accentPink),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                final navigator = context;
                DeleteDialog.show(
                  context,
                  title: 'Delete Project?',
                  content: 'All tasks and notes in this project will be lost.',
                  onDelete: () async {
                    await ref
                        .read(projectsControllerProvider.notifier)
                        .deleteProject(project.id);
                    if (mounted) navigator.pop();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => EditProjectSheet(
        project: project,
        onSave: (name, description, colorValue, emoji, startDate, endDate, category) {
          ref.read(projectsControllerProvider.notifier).updateProject(
            id: project.id,
            name: name,
            description: description,
            colorValue: colorValue,
            emoji: emoji,
            startDate: startDate,
            endDate: endDate,
            category: category,
          );
          AppToast.show(
            this.context,
            message: 'Project updated successfully',
            type: ToastType.success,
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt, color: AppColors.primary),
              title: const Text(
                'New Task',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showAddTaskDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: AppColors.secondary),
              title: const Text(
                'New Note',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                // Navigate to note editor with project ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorView(
                      parentId: widget.projectId,
                      parentType: 0, // 0 = Project
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          DetailedAddTaskSheet(initialProjectId: widget.projectId),
    );
  }

  Widget _buildDismissibleTask(Task task) {
    return Dismissible(
      key: Key('project_task_${task.id}'),
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
        onLongPress: () {
          if (Platform.isIOS) {
            HapticFeedback.mediumImpact();
          }
          _showTaskOptions(task);
        },
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
                _confirmDeleteTask(task);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTask(Task task) {
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
}

/// Modern Edit Project Sheet
class EditProjectSheet extends StatefulWidget {
  final Project project;
  final Function(String name, String? description, int colorValue, String? emoji, DateTime? startDate, DateTime? endDate, int category) onSave;

  const EditProjectSheet({
    super.key,
    required this.project,
    required this.onSave,
  });

  @override
  State<EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends State<EditProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late Color _selectedColor;
  late String _selectedEmoji;
  DateTime? _startDate;
  DateTime? _endDate;
  late int _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description ?? '');
    _selectedColor = Color(widget.project.colorValue);
    _selectedEmoji = widget.project.emoji ?? '📁';
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _selectedCategory = widget.project.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                      'Edit Project',
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
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Project Name *',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a project name';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Project name',
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
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'What is this project about?',
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
                // Category selector
                const Text(
                  'Category (Optional)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategoryChip(ProjectCategory.none, 'None', Icons.remove_circle_outline),
                    const SizedBox(width: 8),
                    _buildCategoryChip(ProjectCategory.work, 'Work', Icons.work_outline),
                    const SizedBox(width: 8),
                    _buildCategoryChip(ProjectCategory.personal, 'Personal', Icons.person_outline),
                  ],
                ),
                const SizedBox(height: 16),
                // Date Range
                const Text(
                  'Date Range (Optional)',
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
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (date != null) setState(() => _startDate = date);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start',
                                style: TextStyle(fontSize: 10, color: Colors.white38),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                    : 'Set date',
                                style: TextStyle(
                                  color: _startDate != null ? Colors.white : Colors.white24,
                                  fontSize: 13,
                                ),
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
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End',
                                style: TextStyle(fontSize: 10, color: Colors.white38),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                    : 'Set date',
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
                const SizedBox(height: 16),
                // Color picker
                const Text(
                  'Project Color',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: projectColors.map((color) {
                    final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
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
              children: projectEmojis.map((emoji) {
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

  Widget _buildCategoryChip(int category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        _selectedColor.toARGB32(),
        _selectedEmoji,
        _startDate,
        _endDate,
        _selectedCategory,
      );
      Navigator.pop(context);
    }
  }
}
