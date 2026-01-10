import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/features/notes/presentation/notes_controller.dart';
import 'package:mindfree/features/notes/presentation/document_capture_sheet.dart';
import 'package:mindfree/data/repositories/note_repository.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:intl/intl.dart';

class NotesListView extends ConsumerStatefulWidget {
  const NotesListView({super.key});

  @override
  ConsumerState<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends ConsumerState<NotesListView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);

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
                    'My Notes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showDocumentCapture(),
                    child: const GlassCard(
                      borderRadius: 12,
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
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
              const SizedBox(height: 24),

              // Notes List
              Expanded(
                child: notesAsync.when(
                  data: (notes) {
                    var filteredNotes = notes;
                    if (_searchQuery.isNotEmpty) {
                      filteredNotes = notes.where((n) {
                        return n.content
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    if (filteredNotes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching notes'
                                  : 'No notes yet. Start writing!',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(allNotesProvider);
                      },
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _NoteListItem(
                            note: note,
                            onDelete: () => _confirmDelete(note),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Note',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(noteRepositoryProvider).deleteNote(note.id);
              ref.invalidate(allNotesProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Note deleted'),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

  void _showDocumentCapture() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DocumentCaptureSheet(),
    );
  }
}

class _NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  const _NoteListItem({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM dd, yyyy').format(note.createdAt);
    // Extract first line as title
    final firstLine = note.content.split('\n').first.replaceAll('#', '').trim();
    final title = firstLine.isEmpty ? 'Untitled Note' : firstLine;
    final preview = note.content.split('\n').skip(1).join(' ').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push('/note_editor', extra: note),
        onLongPress: onDelete,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: note.parentType == 0
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.parentType == 0 ? 'Project' : 'Task',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: note.parentType == 0
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (preview.isNotEmpty)
                Text(
                  preview,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
