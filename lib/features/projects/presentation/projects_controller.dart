import 'package:isar/isar.dart';
import 'package:mindfree/data/models/project.dart';
import 'package:mindfree/data/repositories/project_repository.dart';
import 'package:mindfree/data/repositories/task_repository.dart';
import 'package:mindfree/data/repositories/note_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'projects_controller.g.dart';

@riverpod
class ProjectsController extends _$ProjectsController {
  @override
  Stream<List<Project>> build() {
    return ref.watch(projectRepositoryProvider).watchProjects();
  }

  Future<void> addProject({
    required String name,
    String? description,
    required int colorValue,
    String? emoji,
    DateTime? startDate,
    DateTime? endDate,
    int category = 0,
  }) async {
    // Get the max sortOrder to put new project at the end
    final projects = await ref.read(projectRepositoryProvider).getAllProjects();
    final maxSortOrder = projects.isEmpty
        ? 0
        : projects.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    final project = Project()
      ..name = name
      ..description = description
      ..colorValue = colorValue
      ..emoji = emoji
      ..startDate = startDate
      ..endDate = endDate
      ..category = category
      ..sortOrder = maxSortOrder
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await ref.read(projectRepositoryProvider).saveProject(project);
  }

  Future<void> deleteProject(Id id) async {
    // Delete associated tasks first
    await ref.read(taskRepositoryProvider).deleteTasksByProject(id);
    // Delete associated notes (parentType 0 = Project)
    await ref.read(noteRepositoryProvider).deleteNotesByParent(0, id);
    // Then delete the project
    await ref.read(projectRepositoryProvider).deleteProject(id);
  }

  Future<void> updateProject({
    required Id id,
    required String name,
    String? description,
    int? colorValue,
    String? emoji,
    DateTime? startDate,
    DateTime? endDate,
    int? category,
  }) async {
    final existing = await ref
        .read(projectRepositoryProvider)
        .getProjectById(id);
    if (existing != null) {
      existing
        ..name = name
        ..description = description ?? existing.description
        ..colorValue = colorValue ?? existing.colorValue
        ..emoji = emoji ?? existing.emoji
        ..startDate = startDate
        ..endDate = endDate
        ..category = category ?? existing.category
        ..updatedAt = DateTime.now();
      await ref.read(projectRepositoryProvider).saveProject(existing);
    }
  }

  /// Update sort orders after drag-drop reordering
  Future<void> updateSortOrders(List<Project> projects) async {
    for (int i = 0; i < projects.length; i++) {
      projects[i].sortOrder = i;
    }
    await ref.read(projectRepositoryProvider).updateSortOrders(projects);
  }

  /// Toggle project completion status
  Future<void> toggleProjectCompletion(Project project) async {
    project.isCompleted = !project.isCompleted;
    project.updatedAt = DateTime.now();
    await ref.read(projectRepositoryProvider).saveProject(project);
  }
}
