import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/core/widgets/app_toast.dart';
import 'package:mindfree/features/settings/presentation/user_profile_controller.dart';
import 'package:mindfree/features/settings/presentation/tags_controller.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarPath = ref.watch(userAvatarControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar Section
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarOptions(context, ref),
              child: Stack(
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        image: DecorationImage(
                          image: avatarPath != null && File(avatarPath).existsSync()
                              ? FileImage(File(avatarPath))
                              : const AssetImage('assets/images/logo.jpg') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap to change avatar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Account',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.person_outline_rounded,
                  'Profile',
                  ref
                      .watch(userProfileControllerProvider)
                      .maybeWhen(data: (name) => name, orElse: () => 'Atef'),
                  onTap: () => _showNameEditDialog(context, ref),
                ),
                _buildDivider(),
                _buildSettingTile(
                  Icons.email_rounded,
                  'Email',
                  'atef@mindfree.app',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Preferences',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.email_rounded,
                  'Email Notifications',
                  'Get updates about your tasks',
                  isSwitch: true,
                  initialValue: true,
                ),
                _buildDivider(),
                _buildSettingTile(
                  Icons.notifications_active_rounded,
                  'Push Notifications',
                  'Alerts on your device',
                  isSwitch: true,
                  initialValue: true,
                ),
                _buildDivider(),
                _buildSettingTile(
                  Icons.music_note_rounded,
                  'Notification Sound',
                  'Default',
                  onTap: () => _showSoundPicker(context),
                ),
                _buildDivider(),
                _buildSettingTile(
                  Icons.language_rounded,
                  'Language',
                  'English',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Data Management',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.label_rounded,
                  'Manage Tags',
                  ref.watch(tagsControllerProvider).maybeWhen(
                        data: (tags) => '${tags.length} tags',
                        orElse: () => '',
                      ),
                  onTap: () => _showTagsManager(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'App Info',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.info_outline_rounded,
                  'Version',
                  '1.0.0',
                ),
                _buildDivider(),
                _buildSettingTile(Icons.policy_outlined, 'Privacy Policy', ''),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.secondary),
              ),
              title: const Text(
                'Take a Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(context, ref, ImageSource.camera);
              },
            ),
            if (ref.read(userAvatarControllerProvider).valueOrNull != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.accentPink),
                ),
                title: const Text(
                  'Remove Avatar',
                  style: TextStyle(color: AppColors.accentPink),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(userAvatarControllerProvider.notifier).updateAvatar(null);
                  AppToast.show(
                    context,
                    message: 'Avatar removed',
                    type: ToastType.info,
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Save to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';

        // Copy file to app directory
        await File(pickedFile.path).copy(savedPath);

        // Update avatar path
        ref.read(userAvatarControllerProvider.notifier).updateAvatar(savedPath);

        if (context.mounted) {
          AppToast.show(
            context,
            message: 'Avatar updated successfully',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Failed to update avatar',
          type: ToastType.error,
        );
      }
    }
  }

  void _showSoundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SoundPickerSheet(),
    );
  }

  void _showTagsManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _TagsManagerSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showNameEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(userProfileControllerProvider).value ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(userProfileControllerProvider.notifier)
                    .updateName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String value, {
    bool isSwitch = false,
    bool initialValue = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isSwitch
          ? Switch(
              value: initialValue,
              onChanged: (v) {},
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              activeThumbColor: AppColors.primary,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(color: Colors.white54)),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white24,
                ),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}

class _SoundPickerSheet extends StatefulWidget {
  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedSound = 'default';
  String? _playingSound;

  // Map sound IDs to iOS system sound IDs
  // These are iOS system sound IDs that can be played
  static const Map<String, int> _soundIds = {
    'default': 1007, // Tink
    'chime': 1013, // Chime
    'bell': 1009, // Tock
    'ping': 1003, // Ping
    'pop': 1004, // Pop
    'ding': 1016, // Tweet
    'soft': 1001, // Mail Sent
  };

  static const List<Map<String, String>> _sounds = [
    {'name': 'Default', 'id': 'default'},
    {'name': 'Chime', 'id': 'chime'},
    {'name': 'Bell', 'id': 'bell'},
    {'name': 'Ping', 'id': 'ping'},
    {'name': 'Pop', 'id': 'pop'},
    {'name': 'Ding', 'id': 'ding'},
    {'name': 'Soft', 'id': 'soft'},
    {'name': 'None', 'id': 'none'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundId) async {
    if (soundId == 'none') return;

    setState(() {
      _playingSound = soundId;
    });

    try {
      // Use system sound on iOS via haptic feedback + audio
      // For cross-platform, we use a system sound approach
      await HapticFeedback.selectionClick();

      // Play iOS system sound
      final systemSoundId = _soundIds[soundId] ?? 1007;

      // On iOS, we can use the native sound
      if (Platform.isIOS) {
        // Use method channel to play system sound
        const channel = MethodChannel('mindfree/audio');
        try {
          await channel.invokeMethod('playSystemSound', {'soundId': systemSoundId});
        } catch (e) {
          // Fallback: Use AudioPlayer with a bundled sound or notification
          await _audioPlayer.play(AssetSource('sounds/$soundId.mp3'));
        }
      } else {
        // Android/other platforms
        await _audioPlayer.play(AssetSource('sounds/$soundId.mp3'));
      }
    } catch (e) {
      // If audio fails, at least give haptic feedback
      await HapticFeedback.mediumImpact();
    }

    // Show playing state briefly
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _playingSound = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notification Sound',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the play button to preview',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          ..._sounds.map((sound) {
            final soundId = sound['id']!;
            final isSelected = _selectedSound == soundId;
            final isPlaying = _playingSound == soundId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    color: isSelected ? Colors.white : Colors.white38,
                    size: 18,
                  ),
                ),
                title: Text(
                  sound['name']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: soundId != 'none'
                    ? GestureDetector(
                        onTap: () => _playSound(soundId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.secondary
                                : Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? Colors.white : Colors.white70,
                            size: 20,
                          ),
                        ),
                      )
                    : const SizedBox(width: 36),
                onTap: () {
                  setState(() {
                    _selectedSound = soundId;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                AppToast.show(
                  context,
                  message: 'Sound changed to ${_sounds.firstWhere((s) => s['id'] == _selectedSound)['name']}',
                  type: ToastType.success,
                );
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TagsManagerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _TagsManagerSheet({required this.scrollController});

  @override
  ConsumerState<_TagsManagerSheet> createState() => _TagsManagerSheetState();
}

class _TagsManagerSheetState extends ConsumerState<_TagsManagerSheet> {
  final _newTagController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _newTagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _newTagController.text.trim().toLowerCase();
    if (tag.isNotEmpty) {
      ref.read(tagsControllerProvider.notifier).addTag(tag);
      _newTagController.clear();
      _focusNode.requestFocus();
    }
  }

  void _deleteTag(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tag', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$tag"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tagsControllerProvider.notifier).removeTag(tag);
              Navigator.pop(context);
              AppToast.show(
                this.context,
                message: 'Tag deleted',
                type: ToastType.info,
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.accentPink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsControllerProvider);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.accentBlue],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.label_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manage Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add, edit, or delete your task tags',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Add new tag input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add new tag...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tags list
          Expanded(
            child: tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label_off_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tags yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  scrollController: widget.scrollController,
                  itemCount: tags.length,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(tagsControllerProvider.notifier).reorderTags(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return Container(
                      key: ValueKey(tag),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.label_rounded,
                            color: _getTagColor(tag),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _deleteTag(tag),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPink.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  color: AppColors.accentPink,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.drag_handle_rounded,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text(
                  'Error loading tags',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reset button
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Reset Tags', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'This will reset all tags to defaults. Are you sure?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(tagsControllerProvider.notifier).resetToDefaults();
                              Navigator.pop(context);
                              AppToast.show(
                                this.context,
                                message: 'Tags reset to defaults',
                                type: ToastType.success,
                              );
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset to Defaults'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String tag) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentPink,
    ];
    return colors[tag.hashCode.abs() % colors.length];
  }
}
