import 'package:isar/isar.dart';
import 'package:mindfree/data/models/task.dart';
import 'package:mindfree/data/services/isar_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final Isar isar;
  TaskRepository(this.isar);

  Future<List<Task>> getAllTasks() async {
    return isar.tasks.where().findAll();
  }

  Stream<List<Task>> watchAllTasks() {
    return isar.tasks.where().watch(fireImmediately: true);
  }

  Future<List<Task>> getTasksByProject(int projectId) async {
    return isar.tasks.filter().projectIdEqualTo(projectId).findAll();
  }

  Stream<List<Task>> watchTasksByProject(int projectId) {
    return isar.tasks
        .filter()
        .projectIdEqualTo(projectId)
        .watch(fireImmediately: true);
  }

  Future<int> getTaskCountByProject(int projectId) async {
    return isar.tasks.filter().projectIdEqualTo(projectId).count();
  }

  Stream<int> watchTaskCountByProject(int projectId) {
    return isar.tasks
        .filter()
        .projectIdEqualTo(projectId)
        .watchLazy()
        .asyncMap((_) => getTaskCountByProject(projectId));
  }

  Future<void> saveTask(Task task) async {
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
  }

  Future<void> deleteTask(Id id) async {
    await isar.writeTxn(() async {
      await isar.tasks.delete(id);
    });
  }

  Future<void> deleteTasksByProject(int projectId) async {
    await isar.writeTxn(() async {
      await isar.tasks.filter().projectIdEqualTo(projectId).deleteAll();
    });
  }

  Future<List<Task>> getCompletedTasksInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return isar.tasks
        .filter()
        .isCompletedEqualTo(true)
        .updatedAtBetween(start, end)
        .findAll();
  }

  Future<int> calculateStreak() async {
    int streak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final dayStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completedTasks = await isar.tasks
          .filter()
          .isCompletedEqualTo(true)
          .updatedAtBetween(dayStart, dayEnd)
          .count();

      if (completedTasks > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Watch all tasks sorted by sortOrder
  Stream<List<Task>> watchAllTasksSorted() {
    return isar.tasks.where().sortBySortOrder().watch(fireImmediately: true);
  }

  /// Update sort orders for multiple tasks in a single transaction
  Future<void> updateSortOrders(List<Task> tasks) async {
    await isar.writeTxn(() async {
      await isar.tasks.putAll(tasks);
    });
  }

  /// Get overdue tasks (due date before today and not completed)
  Future<List<Task>> getOverdueTasks() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .dueDateIsNotNull()
        .dueDateLessThan(startOfToday)
        .findAll();
  }

  /// Watch overdue tasks
  Stream<List<Task>> watchOverdueTasks() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .dueDateIsNotNull()
        .dueDateLessThan(startOfToday)
        .watch(fireImmediately: true);
  }
}

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) throw Exception('Isar not initialized');
  return TaskRepository(isar);
}
