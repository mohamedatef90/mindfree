import 'package:mindfree/data/models/task.dart';
import 'package:mindfree/data/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_controller.g.dart';

@riverpod
class TasksController extends _$TasksController {
  @override
  Stream<List<Task>> build() {
    return ref.watch(taskRepositoryProvider).watchAllTasks();
  }

  Future<void> addTask({
    int? projectId,
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? endDate,
    DateTime? reminderTime,
    int priority = 1,
    String? emoji,
    List<String>? subtasks,
    List<String>? tags,
  }) async {
    final task = Task()
      ..projectId = projectId
      ..title = title
      ..description = description
      ..dueDate = dueDate
      ..endDate = endDate
      ..reminderTime = reminderTime
      ..priority = priority
      ..emoji = emoji
      ..subtasks = subtasks
      ..tags = tags
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await ref.read(taskRepositoryProvider).saveTask(task);
  }

  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    await ref.read(taskRepositoryProvider).saveTask(task);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    task.updatedAt = DateTime.now();
    await ref.read(taskRepositoryProvider).saveTask(task);
  }

  Future<void> deleteTask(int id) async {
    await ref.read(taskRepositoryProvider).deleteTask(id);
  }

  Future<void> toggleSubtask(Task task, int subtaskIndex) async {
    final subtaskItems = task.subtaskItems;
    if (subtaskIndex >= 0 && subtaskIndex < subtaskItems.length) {
      // Create a new list with the toggled subtask
      final updatedSubtasks = subtaskItems.asMap().entries.map((entry) {
        if (entry.key == subtaskIndex) {
          return entry.value.copyWith(isCompleted: !entry.value.isCompleted);
        }
        return entry.value;
      }).toList();

      task.setSubtaskItems(updatedSubtasks);
      task.updatedAt = DateTime.now();
      await ref.read(taskRepositoryProvider).saveTask(task);
    }
  }

  /// Update sort orders after drag-drop reordering
  Future<void> updateSortOrders(List<Task> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      tasks[i].sortOrder = i;
    }
    await ref.read(taskRepositoryProvider).updateSortOrders(tasks);
  }
}

@riverpod
Stream<List<Task>> projectTasks(ProjectTasksRef ref, int projectId) {
  return ref.watch(taskRepositoryProvider).watchTasksByProject(projectId);
}

@riverpod
Future<int> taskStreak(TaskStreakRef ref) {
  return ref.watch(taskRepositoryProvider).calculateStreak();
}

@riverpod
Stream<int> projectTaskCount(ProjectTaskCountRef ref, int projectId) {
  return ref.watch(taskRepositoryProvider).watchTaskCountByProject(projectId);
}

@riverpod
Stream<List<Task>> overdueTasks(OverdueTasksRef ref) {
  return ref.watch(taskRepositoryProvider).watchOverdueTasks();
}
