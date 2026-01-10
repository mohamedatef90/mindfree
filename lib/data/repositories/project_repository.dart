import 'package:isar/isar.dart';
import 'package:mindfree/data/models/project.dart';
import 'package:mindfree/data/services/isar_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_repository.g.dart';

class ProjectRepository {
  final Isar isar;
  ProjectRepository(this.isar);

  Future<List<Project>> getAllProjects() async {
    return isar.projects.where().findAll();
  }

  Stream<List<Project>> watchProjects() {
    return isar.projects.where().watch(fireImmediately: true);
  }

  Future<void> saveProject(Project project) async {
    await isar.writeTxn(() async {
      await isar.projects.put(project);
    });
  }

  Future<void> deleteProject(Id id) async {
    await isar.writeTxn(() async {
      await isar.projects.delete(id);
    });
  }

  Future<Project?> getProjectById(Id id) async {
    return isar.projects.get(id);
  }

  /// Watch projects sorted by sortOrder
  Stream<List<Project>> watchProjectsSorted() {
    return isar.projects
        .where()
        .sortBySortOrder()
        .watch(fireImmediately: true);
  }

  /// Update sort orders for multiple projects in a single transaction
  Future<void> updateSortOrders(List<Project> projects) async {
    await isar.writeTxn(() async {
      await isar.projects.putAll(projects);
    });
  }

  /// Get projects by category
  Future<List<Project>> getProjectsByCategory(int category) async {
    return isar.projects.filter().categoryEqualTo(category).findAll();
  }

  /// Watch projects by category, sorted by sortOrder
  Stream<List<Project>> watchProjectsByCategory(int category) {
    return isar.projects
        .filter()
        .categoryEqualTo(category)
        .sortBySortOrder()
        .watch(fireImmediately: true);
  }
}

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) throw Exception('Isar not initialized');
  return ProjectRepository(isar);
}
