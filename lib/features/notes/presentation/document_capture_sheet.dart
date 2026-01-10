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

class DocumentCaptureSheet extends ConsumerStatefulWidget {
  final int? parentId;
  final int? parentType;

  const DocumentCaptureSheet({
    super.key,
    this.parentId,
    this.parentType,
  });

  @override
  ConsumerState<DocumentCaptureSheet> createState() => _DocumentCaptureSheetState();
}

class _DocumentCaptureSheetState extends ConsumerState<DocumentCaptureSheet> {
  bool _isProcessing = false;
  String? _extractedText;
  String? _imagePath;
  File? _capturedImage;

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
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        AppToast.show(
          context,
          message: 'Error capturing document: $e',
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GlassCard(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Document',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Capture a document and extract text using AI',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),

              // Content based on state
              if (_isProcessing)
                _buildProcessingState()
              else if (_extractedText != null)
                Expanded(child: _buildResultState(scrollController))
              else
                _buildInitialState(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        // Camera option
        _buildSourceOption(
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Capture document with camera',
          color: AppColors.primary,
          onTap: () => _captureDocument(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        // Gallery option
        _buildSourceOption(
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Select existing image',
          color: AppColors.secondary,
          onTap: () => _captureDocument(ImageSource.gallery),
        ),
        const SizedBox(height: 24),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
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
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildResultState(ScrollController scrollController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview
        if (_capturedImage != null)
          Container(
            height: 120,
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
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
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
        // Action buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _editFirst,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Edit First',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveDirectly,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Directly',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      ],
    );
  }
}
