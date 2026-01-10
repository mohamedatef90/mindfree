import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  int? projectId;

  @Index()
  late String title;

  String? description;

  DateTime? dueDate;
  DateTime? endDate;

  bool isCompleted = false;

  late int priority; // 0: low, 1: medium, 2: high

  int? reminderId;
  DateTime? reminderTime;

  late DateTime createdAt;

  late DateTime updatedAt;

  String? emoji;

  // Tags for categorization
  List<String>? tags;

  // Sort order for manual ordering
  int sortOrder = 0;

  // Subtasks stored as "title|completed" format (e.g., "Buy milk|false")
  List<String>? subtasks;

  // Helper to get subtask items as objects
  @ignore
  List<SubtaskItem> get subtaskItems {
    if (subtasks == null || subtasks!.isEmpty) return [];
    return subtasks!.map((s) {
      final parts = s.split('|');
      return SubtaskItem(
        title: parts[0],
        isCompleted: parts.length > 1 && parts[1] == 'true',
      );
    }).toList();
  }

  // Helper to set subtasks from SubtaskItem list
  void setSubtaskItems(List<SubtaskItem> items) {
    subtasks = items.map((item) => '${item.title}|${item.isCompleted}').toList();
  }

  // Get completed subtask count
  @ignore
  int get completedSubtaskCount {
    return subtaskItems.where((s) => s.isCompleted).length;
  }
}

// Helper class for subtasks (not stored in Isar)
class SubtaskItem {
  final String title;
  final bool isCompleted;

  SubtaskItem({required this.title, this.isCompleted = false});

  SubtaskItem copyWith({String? title, bool? isCompleted}) {
    return SubtaskItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
