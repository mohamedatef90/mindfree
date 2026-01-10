import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:mindfree/features/notes/presentation/notes_controller.dart';
import 'package:mindfree/features/notes/presentation/document_capture_sheet.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorView extends ConsumerStatefulWidget {
  final Note? note;
  final int? parentId;
  final int? parentType;
  final String? initialContent;
  final String? attachmentPath;

  const NoteEditorView({
    super.key,
    this.note,
    this.parentId,
    this.parentType,
    this.initialContent,
    this.attachmentPath,
  });

  @override
  ConsumerState<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends ConsumerState<NoteEditorView> {
  late TextEditingController _controller;
  bool _isPreview = false;
  bool _showToolbar = true;
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.note?.content ?? widget.initialContent ?? '',
    );
    _attachmentPath = widget.attachmentPath ?? widget.note?.attachmentPaths?.firstOrNull;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Insert text at cursor position or wrap selection
  void _insertFormat(String prefix, [String? suffix]) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0) {
      // No selection, append at the end
      _controller.text = text + prefix + (suffix ?? '');
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length - (suffix?.length ?? 0),
      );
      return;
    }

    if (start == end) {
      // No selection, just insert prefix
      final newText = text.substring(0, start) + prefix + text.substring(end);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: start + prefix.length,
      );
    } else {
      // Wrap selection
      final selectedText = text.substring(start, end);
      final newText = text.substring(0, start) +
          prefix +
          selectedText +
          (suffix ?? prefix) +
          text.substring(end);
      _controller.text = newText;
      _controller.selection = TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      );
    }
    setState(() {});
  }

  // Insert at beginning of current line
  void _insertLinePrefix(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.start >= 0 ? selection.start : text.length;

    // Find the start of the current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Check if prefix already exists
    if (text.substring(lineStart).startsWith(prefix)) {
      // Remove prefix
      final newText =
          text.substring(0, lineStart) + text.substring(lineStart + prefix.length);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: cursorPos - prefix.length,
      );
    } else {
      // Add prefix
      final newText =
          text.substring(0, lineStart) + prefix + text.substring(lineStart);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      // Toggle toolbar visibility
                      IconButton(
                        icon: Icon(
                          _showToolbar
                              ? Icons.keyboard_hide_rounded
                              : Icons.keyboard_rounded,
                          color: _showToolbar ? AppColors.primary : Colors.white70,
                        ),
                        onPressed: () => setState(() => _showToolbar = !_showToolbar),
                        tooltip: _showToolbar ? 'Hide toolbar' : 'Show toolbar',
                      ),
                      IconButton(
                        icon: Icon(
                          _isPreview
                              ? Icons.edit_rounded
                              : Icons.visibility_rounded,
                          color: _isPreview ? AppColors.primary : Colors.white70,
                        ),
                        onPressed: () => setState(() => _isPreview = !_isPreview),
                        tooltip: _isPreview ? 'Edit' : 'Preview',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: _showDocumentCapture,
                        tooltip: 'Scan Document',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: _controller.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Formatting Toolbar
            if (_showToolbar && !_isPreview) _buildFormattingToolbar(),

            // Editor / Preview
            Expanded(
              child: _isPreview
                  ? Markdown(
                      data: _controller.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        h1: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: const TextStyle(color: AppColors.primary),
                        code: TextStyle(
                          color: AppColors.accentPink,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        blockquote: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 4,
                            ),
                          ),
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        checkbox: TextStyle(
                          color: AppColors.accentGreen,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Start writing your note...\n\nTip: Use the toolbar above for formatting!',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                        autofocus: widget.note == null,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Text Style Group
              _buildToolbarGroup([
                _ToolbarButton(
                  icon: Icons.title_rounded,
                  label: 'H1',
                  onTap: () => _insertLinePrefix('# '),
                  tooltip: 'Heading 1',
                ),
                _ToolbarButton(
                  icon: Icons.text_fields_rounded,
                  label: 'H2',
                  onTap: () => _insertLinePrefix('## '),
                  tooltip: 'Heading 2',
                ),
                _ToolbarButton(
                  icon: Icons.text_fields_rounded,
                  label: 'H3',
                  onTap: () => _insertLinePrefix('### '),
                  tooltip: 'Heading 3',
                  small: true,
                ),
              ]),
              _buildDivider(),

              // Text Format Group
              _buildToolbarGroup([
                _ToolbarButton(
                  icon: Icons.format_bold_rounded,
                  onTap: () => _insertFormat('**'),
                  tooltip: 'Bold',
                ),
                _ToolbarButton(
                  icon: Icons.format_italic_rounded,
                  onTap: () => _insertFormat('*'),
                  tooltip: 'Italic',
                ),
                _ToolbarButton(
                  icon: Icons.strikethrough_s_rounded,
                  onTap: () => _insertFormat('~~'),
                  tooltip: 'Strikethrough',
                ),
                _ToolbarButton(
                  icon: Icons.code_rounded,
                  onTap: () => _insertFormat('`'),
                  tooltip: 'Inline Code',
                ),
              ]),
              _buildDivider(),

              // List Group
              _buildToolbarGroup([
                _ToolbarButton(
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: () => _insertLinePrefix('- '),
                  tooltip: 'Bullet List',
                ),
                _ToolbarButton(
                  icon: Icons.format_list_numbered_rounded,
                  onTap: () => _insertLinePrefix('1. '),
                  tooltip: 'Numbered List',
                ),
                _ToolbarButton(
                  icon: Icons.check_box_outlined,
                  onTap: () => _insertLinePrefix('- [ ] '),
                  tooltip: 'Checkbox',
                ),
              ]),
              _buildDivider(),

              // Insert Group
              _buildToolbarGroup([
                _ToolbarButton(
                  icon: Icons.format_quote_rounded,
                  onTap: () => _insertLinePrefix('> '),
                  tooltip: 'Quote',
                ),
                _ToolbarButton(
                  icon: Icons.link_rounded,
                  onTap: () => _showLinkDialog(),
                  tooltip: 'Link',
                ),
                _ToolbarButton(
                  icon: Icons.horizontal_rule_rounded,
                  onTap: () => _insertFormat('\n---\n'),
                  tooltip: 'Horizontal Line',
                ),
                _ToolbarButton(
                  icon: Icons.data_object_rounded,
                  onTap: () => _insertFormat('\n```\n', '\n```\n'),
                  tooltip: 'Code Block',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarGroup(List<Widget> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  void _showLinkDialog() {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    // Get selected text
    final selection = _controller.selection;
    if (selection.start >= 0 && selection.start != selection.end) {
      textController.text =
          _controller.text.substring(selection.start, selection.end);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Insert Link',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Link text',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'URL (https://...)',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.isNotEmpty
                  ? textController.text
                  : 'Link';
              final url =
                  urlController.text.isNotEmpty ? urlController.text : '#';
              _insertFormat('[$text]($url)');
              Navigator.pop(context);
            },
            child: const Text('Insert'),
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
      builder: (context) => DocumentCaptureSheet(
        parentId: widget.note?.parentId ?? widget.parentId ?? 0,
        parentType: widget.note?.parentType ?? widget.parentType ?? 0,
      ),
    );
  }

  void _save() {
    if (_controller.text.isNotEmpty) {
      ref.read(notesControllerProvider.notifier).saveNote(
            id: widget.note?.id,
            parentId: widget.note?.parentId ?? widget.parentId ?? 0,
            parentType: widget.note?.parentType ?? widget.parentType ?? 0,
            content: _controller.text,
          );
      Navigator.pop(context);

      AppToast.show(
        context,
        message: 'Note saved',
        type: ToastType.success,
      );
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final String tooltip;
  final bool small;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: small ? 12 : 14,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white70,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
