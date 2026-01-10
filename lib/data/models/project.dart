import 'package:isar/isar.dart';

part 'project.g.dart';

// Category constants
class ProjectCategory {
  static const int none = 0;
  static const int work = 1;
  static const int personal = 2;

  static String getName(int category) {
    switch (category) {
      case work:
        return 'Work';
      case personal:
        return 'Personal';
      default:
        return 'None';
    }
  }
}

@collection
class Project {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? description;

  late int colorValue;

  DateTime? startDate;
  DateTime? endDate;

  late DateTime createdAt;

  late DateTime updatedAt;

  String? emoji;

  // Category: 0=none, 1=work, 2=personal
  int category = ProjectCategory.none;

  // Sort order for manual ordering
  int sortOrder = 0;

  // Completion status
  bool isCompleted = false;
}
