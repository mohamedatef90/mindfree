import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/features/projects/presentation/projects_controller.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/data/models/project.dart';

// Provider for view mode preference
final projectsViewModeProvider = StateProvider<bool>((ref) => true); // true = grid, false = list

class ProjectsView extends ConsumerStatefulWidget {
  const ProjectsView({super.key});

  @override
  ConsumerState<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends ConsumerState<ProjectsView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _selectedCategory = -1; // -1 = All, 0 = None, 1 = Work, 2 = Personal

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isGridView = prefs.getBool('projects_view_mode') ?? true;
    ref.read(projectsViewModeProvider.notifier).state = isGridView;
  }

  Future<void> _saveViewPreference(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('projects_view_mode', isGridView);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsControllerProvider);
    final isGridView = ref.watch(projectsViewModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header Row
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
                    'Projects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // View toggle button
                  GestureDetector(
                    onTap: () {
                      final newValue = !isGridView;
                      ref.read(projectsViewModeProvider.notifier).state = newValue;
                      _saveViewPreference(newValue);
                    },
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryTab(-1, 'All', Icons.folder_rounded),
                    const SizedBox(width: 8),
                    _buildCategoryTab(ProjectCategory.work, 'Work', Icons.work_rounded),
                    const SizedBox(width: 8),
                    _buildCategoryTab(ProjectCategory.personal, 'Personal', Icons.person_rounded),
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
                    hintText: 'Search projects...',
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
              const SizedBox(height: 20),

              // Projects Grid/List
              Expanded(
                child: projectsAsync.when(
                  data: (projects) {
                    // Sort by sortOrder
                    var sortedProjects = List<Project>.from(projects);
                    sortedProjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                    // Filter by category
                    var filteredProjects = sortedProjects;
                    if (_selectedCategory != -1) {
                      filteredProjects = sortedProjects
                          .where((p) => p.category == _selectedCategory)
                          .toList();
                    }

                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      filteredProjects = filteredProjects.where((p) {
                        return p.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            (p.description
                                    ?.toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ??
                                false);
                      }).toList();
                    }

                    if (filteredProjects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching projects'
                                  : 'No projects yet. Create one!',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(projectsControllerProvider);
                      },
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: isGridView
                          ? _buildGridView(filteredProjects)
                          : _buildListView(filteredProjects),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(int category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Project> projects) {
    return ReorderableGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      onReorder: (oldIndex, newIndex) {
        _handleReorder(projects, oldIndex, newIndex);
      },
      children: projects.map((project) {
        return _ProjectGridItem(
          key: ValueKey(project.id),
          project: project,
          onDelete: () => _confirmDeleteProject(project),
        );
      }).toList(),
    );
  }

  Widget _buildListView(List<Project> projects) {
    return ReorderableListView.builder(
      itemCount: projects.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final project = projects[index];
        return ReorderableDragStartListener(
          key: ValueKey(project.id),
          index: index,
          child: _ProjectListItem(
            project: project,
            onDelete: () => _confirmDeleteProject(project),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        _handleReorder(projects, oldIndex, newIndex);
      },
    );
  }

  void _handleReorder(List<Project> projects, int oldIndex, int newIndex) {
    final reorderedProjects = List<Project>.from(projects);
    final item = reorderedProjects.removeAt(oldIndex);
    reorderedProjects.insert(newIndex, item);
    ref.read(projectsControllerProvider.notifier).updateSortOrders(reorderedProjects);
  }

  void _confirmDeleteProject(Project project) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Project',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${project.name}"? This will also delete all associated tasks and notes.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(projectsControllerProvider.notifier)
                  .deleteProject(project.id);

              AppToast.show(
                context,
                message: 'Deleted "${project.name}"',
                type: ToastType.info,
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
}

class _ProjectGridItem extends ConsumerWidget {
  final Project project;
  final VoidCallback onDelete;

  const _ProjectGridItem({
    super.key,
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskCountAsync = ref.watch(projectTaskCountProvider(project.id));

    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      onLongPress: () {
        if (Platform.isIOS) {
          HapticFeedback.mediumImpact();
        }
        onDelete();
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: project.isCompleted
                        ? AppColors.accentGreen
                        : Color(project.colorValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    if (project.category != ProjectCategory.none)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: project.category == ProjectCategory.work
                              ? AppColors.accentBlue.withValues(alpha: 0.2)
                              : AppColors.accentPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.category == ProjectCategory.work ? 'W' : 'P',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: project.category == ProjectCategory.work
                                ? AppColors.accentBlue
                                : AppColors.accentPink,
                          ),
                        ),
                      ),
                    if (project.emoji != null)
                      Text(project.emoji!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    // Completion toggle
                    GestureDetector(
                      onTap: () {
                        if (Platform.isIOS) {
                          HapticFeedback.lightImpact();
                        }
                        ref.read(projectsControllerProvider.notifier)
                            .toggleProjectCompletion(project);
                      },
                      child: Icon(
                        project.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: project.isCompleted
                            ? AppColors.accentGreen
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: project.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: project.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              project.description ?? 'No description',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${taskCountAsync.valueOrNull ?? 0} ${(taskCountAsync.valueOrNull ?? 0) == 1 ? 'Task' : 'Tasks'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListItem extends ConsumerWidget {
  final Project project;
  final VoidCallback onDelete;

  const _ProjectListItem({
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskCountAsync = ref.watch(projectTaskCountProvider(project.id));

    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      onLongPress: () {
        if (Platform.isIOS) {
          HapticFeedback.mediumImpact();
        }
        onDelete();
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: project.isCompleted
                    ? AppColors.accentGreen
                    : Color(project.colorValue),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Completion toggle
            GestureDetector(
              onTap: () {
                if (Platform.isIOS) {
                  HapticFeedback.lightImpact();
                }
                ref.read(projectsControllerProvider.notifier)
                    .toggleProjectCompletion(project);
              },
              child: Icon(
                project.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: project.isCompleted
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            if (project.emoji != null) ...[
              Text(project.emoji!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: project.isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: project.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.category != ProjectCategory.none)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: project.category == ProjectCategory.work
                                ? AppColors.accentBlue.withValues(alpha: 0.2)
                                : AppColors.accentPink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            project.category == ProjectCategory.work ? 'Work' : 'Personal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: project.category == ProjectCategory.work
                                  ? AppColors.accentBlue
                                  : AppColors.accentPink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description ?? 'No description',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${taskCountAsync.valueOrNull ?? 0}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.drag_handle_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
