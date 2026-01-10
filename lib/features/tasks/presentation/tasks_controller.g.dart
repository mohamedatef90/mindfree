// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectTasksHash() => r'49613771f055b9f5aff7fb40a3c6a3734add4ec7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [projectTasks].
@ProviderFor(projectTasks)
const projectTasksProvider = ProjectTasksFamily();

/// See also [projectTasks].
class ProjectTasksFamily extends Family<AsyncValue<List<Task>>> {
  /// See also [projectTasks].
  const ProjectTasksFamily();

  /// See also [projectTasks].
  ProjectTasksProvider call(
    int projectId,
  ) {
    return ProjectTasksProvider(
      projectId,
    );
  }

  @override
  ProjectTasksProvider getProviderOverride(
    covariant ProjectTasksProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'projectTasksProvider';
}

/// See also [projectTasks].
class ProjectTasksProvider extends AutoDisposeStreamProvider<List<Task>> {
  /// See also [projectTasks].
  ProjectTasksProvider(
    int projectId,
  ) : this._internal(
          (ref) => projectTasks(
            ref as ProjectTasksRef,
            projectId,
          ),
          from: projectTasksProvider,
          name: r'projectTasksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$projectTasksHash,
          dependencies: ProjectTasksFamily._dependencies,
          allTransitiveDependencies:
              ProjectTasksFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  ProjectTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final int projectId;

  @override
  Override overrideWith(
    Stream<List<Task>> Function(ProjectTasksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectTasksProvider._internal(
        (ref) => create(ref as ProjectTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Task>> createElement() {
    return _ProjectTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectTasksProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProjectTasksRef on AutoDisposeStreamProviderRef<List<Task>> {
  /// The parameter `projectId` of this provider.
  int get projectId;
}

class _ProjectTasksProviderElement
    extends AutoDisposeStreamProviderElement<List<Task>> with ProjectTasksRef {
  _ProjectTasksProviderElement(super.provider);

  @override
  int get projectId => (origin as ProjectTasksProvider).projectId;
}

String _$taskStreakHash() => r'4d65eac52047049e8345c8eb4590b6617a2b6469';

/// See also [taskStreak].
@ProviderFor(taskStreak)
final taskStreakProvider = AutoDisposeFutureProvider<int>.internal(
  taskStreak,
  name: r'taskStreakProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$taskStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaskStreakRef = AutoDisposeFutureProviderRef<int>;
String _$projectTaskCountHash() => r'7b55a99f15821e538f510fca8f2ca4529fb59ff0';

/// See also [projectTaskCount].
@ProviderFor(projectTaskCount)
const projectTaskCountProvider = ProjectTaskCountFamily();

/// See also [projectTaskCount].
class ProjectTaskCountFamily extends Family<AsyncValue<int>> {
  /// See also [projectTaskCount].
  const ProjectTaskCountFamily();

  /// See also [projectTaskCount].
  ProjectTaskCountProvider call(
    int projectId,
  ) {
    return ProjectTaskCountProvider(
      projectId,
    );
  }

  @override
  ProjectTaskCountProvider getProviderOverride(
    covariant ProjectTaskCountProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'projectTaskCountProvider';
}

/// See also [projectTaskCount].
class ProjectTaskCountProvider extends AutoDisposeStreamProvider<int> {
  /// See also [projectTaskCount].
  ProjectTaskCountProvider(
    int projectId,
  ) : this._internal(
          (ref) => projectTaskCount(
            ref as ProjectTaskCountRef,
            projectId,
          ),
          from: projectTaskCountProvider,
          name: r'projectTaskCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$projectTaskCountHash,
          dependencies: ProjectTaskCountFamily._dependencies,
          allTransitiveDependencies:
              ProjectTaskCountFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  ProjectTaskCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final int projectId;

  @override
  Override overrideWith(
    Stream<int> Function(ProjectTaskCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectTaskCountProvider._internal(
        (ref) => create(ref as ProjectTaskCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _ProjectTaskCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectTaskCountProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProjectTaskCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `projectId` of this provider.
  int get projectId;
}

class _ProjectTaskCountProviderElement
    extends AutoDisposeStreamProviderElement<int> with ProjectTaskCountRef {
  _ProjectTaskCountProviderElement(super.provider);

  @override
  int get projectId => (origin as ProjectTaskCountProvider).projectId;
}

String _$overdueTasksHash() => r'821bf6d5669c7c58de2483f4a2be1d53aa0ae73d';

/// See also [overdueTasks].
@ProviderFor(overdueTasks)
final overdueTasksProvider = AutoDisposeStreamProvider<List<Task>>.internal(
  overdueTasks,
  name: r'overdueTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$overdueTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OverdueTasksRef = AutoDisposeStreamProviderRef<List<Task>>;
String _$tasksControllerHash() => r'b45ce0d3bf50ac9c986827a8e96d0e7d488ed34a';

/// See also [TasksController].
@ProviderFor(TasksController)
final tasksControllerProvider =
    AutoDisposeStreamNotifierProvider<TasksController, List<Task>>.internal(
  TasksController.new,
  name: r'tasksControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tasksControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TasksController = AutoDisposeStreamNotifier<List<Task>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
