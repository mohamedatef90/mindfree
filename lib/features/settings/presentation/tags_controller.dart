import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tags_controller.g.dart';

@riverpod
class TagsController extends _$TagsController {
  static const _tagsKey = 'user_tags';

  // Default tags that come pre-installed
  static const List<String> defaultTags = [
    'work',
    'personal',
    'urgent',
    'meeting',
    'call',
    'email',
    'shopping',
    'health',
    'finance',
    'travel',
    'study',
    'home',
  ];

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTags = prefs.getStringList(_tagsKey);

    if (savedTags == null) {
      // First time - save default tags
      await prefs.setStringList(_tagsKey, defaultTags);
      return defaultTags;
    }

    return savedTags;
  }

  Future<void> addTag(String tag) async {
    final currentTags = state.valueOrNull ?? [];
    final normalizedTag = tag.toLowerCase().trim();

    if (normalizedTag.isEmpty || currentTags.contains(normalizedTag)) {
      return;
    }

    final updatedTags = [...currentTags, normalizedTag];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tagsKey, updatedTags);

    state = AsyncData(updatedTags);
  }

  Future<void> removeTag(String tag) async {
    final currentTags = state.valueOrNull ?? [];
    final updatedTags = currentTags.where((t) => t != tag).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tagsKey, updatedTags);

    state = AsyncData(updatedTags);
  }

  Future<void> reorderTags(int oldIndex, int newIndex) async {
    final currentTags = List<String>.from(state.valueOrNull ?? []);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final tag = currentTags.removeAt(oldIndex);
    currentTags.insert(newIndex, tag);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tagsKey, currentTags);

    state = AsyncData(currentTags);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tagsKey, defaultTags);
    state = AsyncData(defaultTags);
  }
}
