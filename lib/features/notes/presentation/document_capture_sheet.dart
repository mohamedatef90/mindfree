import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/data/services/gemini_service.dart';
import 'package:mindfree/features/notes/presentation/notes_controller.dart';
import 'package:mindfree/features/notes/presentation/note_editor_view.dart';
import 'package:mindfree/features/tasks/presentation/tasks_controller.dart';
import 'package:mindfree/features/projects/presentation/projects_controller.dart';

class DocumentCaptureSheet extends ConsumerStatefulWidget {
  final int? parentId;
  final int? parentType;
  final int? projectId;

  const DocumentCaptureSheet({
    super.key,
    this.parentId,
    this.parentType,
    this.projectId,
  });

  @override
  ConsumerState<DocumentCaptureSheet> createState() => _DocumentCaptureSheetState();
}

class _DocumentCaptureSheetState extends ConsumerState<DocumentCaptureSheet> {
  bool _isProcessing = false;
  String? _extractedText;
  String? _imagePath;
  File? _capturedImage;
  List<String> _lines = [];
  Set<int> _selectedLines = {};
  bool _isTaskMode = false;
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
  }

  Future<void> _captureDocument(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _capturedImage = File(image.path);
      });

      // Save the image to app documents
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');
      if (!documentsDir.existsSync()) {
        documentsDir.createSync(recursive: true);
      }

      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${documentsDir.path}/$fileName';
      await _capturedImage!.copy(savedPath);
      _imagePath = savedPath;

      // Extract text using Gemini OCR
      final imageBytes = await _capturedImage!.readAsBytes();
      final geminiService = ref.read(geminiServiceProvider.notifier);
      final extractedText = await geminiService.extractTextFromImage(imageBytes);

      setState(() {
        _extractedText = extractedText;
        _lines = extractedText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        AppToast.show(
          context,
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _saveDirectly() {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    ref.read(notesControllerProvider.notifier).saveNote(
          parentId: widget.parentId ?? 0,
          parentType: widget.parentType ?? 0,
          content: _extractedText!,
          attachmentPaths: _imagePath != null ? [_imagePath!] : null,
          extractedText: _extractedText,
        );

    Navigator.pop(context);

    AppToast.show(
      context,
      message: 'Note saved from document',
      type: ToastType.success,
    );
  }

  void _editFirst() {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorView(
          parentId: widget.parentId ?? 0,
          parentType: widget.parentType ?? 0,
          initialContent: _extractedText,
          attachmentPath: _imagePath,
        ),
      ),
    );
  }

  void _toggleLineSelection(int index) {
    setState(() {
      if (_selectedLines.contains(index)) {
        _selectedLines.remove(index);
      } else {
        _selectedLines.add(index);
      }
    });
  }

  void _selectAllLines() {
    setState(() {
      if (_selectedLines.length == _lines.length) {
        _selectedLines.clear();
      } else {
        _selectedLines = Set.from(List.generate(_lines.length, (i) => i));
      }
    });
  }

  void _createTasksFromSelected() {
    if (_selectedLines.isEmpty) {
      AppToast.show(
        context,
        message: 'Please select at least one line',
        type: ToastType.warning,
      );
      return;
    }

    // Create tasks from selected lines
    for (final index in _selectedLines) {
      final line = _lines[index].trim();
      if (line.isNotEmpty) {
        ref.read(tasksControllerProvider.notifier).addTask(
              projectId: _selectedProjectId,
              title: line,
              priority: 1,
            );
      }
    }

    Navigator.pop(context);

    AppToast.show(
      context,
      message: '${_selectedLines.length} tasks created',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const GlassCard(
                      borderRadius: 12,
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    _isTaskMode ? 'Create Tasks' : 'Scan Document',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the close button
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isProcessing
                    ? _buildProcessingState()
                    : _extractedText != null
                        ? _isTaskMode
                            ? _buildTaskSelectionState()
                            : _buildResultState()
                        : _buildInitialState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Camera option
        _buildSourceOption(
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Capture document with camera',
          color: AppColors.primary,
          onTap: () => _captureDocument(ImageSource.camera),
        ),
        const SizedBox(height: 16),
        // Gallery option
        _buildSourceOption(
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Select existing image',
          color: AppColors.secondary,
          onTap: () => _captureDocument(ImageSource.gallery),
        ),
        const SizedBox(height: 32),
        // Tips
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tips for best results',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTip('Ensure good lighting'),
              _buildTip('Keep document flat and straight'),
              _buildTip('Avoid shadows and glare'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (Platform.isIOS) {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.accentGreen.withValues(alpha: 0.7),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image preview
        if (_capturedImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_capturedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Extracting text from document...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This may take a few seconds',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResultState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview
        if (_capturedImage != null)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_capturedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.text_snippet_rounded,
              color: AppColors.accentGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Extracted Text',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '${_lines.length} lines',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                _extractedText ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons - First row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _editFirst,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit First'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveDirectly,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save as Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Create Tasks button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isTaskMode = true),
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            label: const Text('Create Tasks from Lines'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Retry button
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _extractedText = null;
                _capturedImage = null;
                _imagePath = null;
                _lines.clear();
                _selectedLines.clear();
              });
            },
            child: Text(
              'Capture Another',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskSelectionState() {
    final projectsAsync = ref.watch(projectsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and instructions
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _isTaskMode = false;
                _selectedLines.clear();
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select lines to convert to tasks',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Project selector
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: projectsAsync.when(
                  data: (projects) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedProjectId,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text(
                          'Select project (optional)',
                          style: TextStyle(color: Colors.white54),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('📥 No Project (Inbox)'),
                          ),
                          ...projects.map(
                            (p) => DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text('${p.emoji ?? "📁"} ${p.name}'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedProjectId = v),
                      ),
                    );
                  },
                  loading: () => const Text(
                    'Loading projects...',
                    style: TextStyle(color: Colors.white54),
                  ),
                  error: (_, __) => const Text(
                    'Error loading projects',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Select all button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedLines.length} of ${_lines.length} selected',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: _selectAllLines,
              child: Text(
                _selectedLines.length == _lines.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lines list with checkboxes
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedLines.contains(index);
                return GestureDetector(
                  onTap: () => _toggleLineSelection(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _lines[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Create tasks button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _selectedLines.isEmpty ? null : _createTasksFromSelected,
            icon: const Icon(Icons.add_task_rounded),
            label: Text(
              _selectedLines.isEmpty
                  ? 'Select lines to create tasks'
                  : 'Create ${_selectedLines.length} Task${_selectedLines.length > 1 ? 's' : ''}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
