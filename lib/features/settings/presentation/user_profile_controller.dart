import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_profile_controller.g.dart';

@riverpod
class UserProfileController extends _$UserProfileController {
  static const _nameKey = 'user_name';

  @override
  FutureOr<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Atef';
  }

  Future<void> updateName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, newName);
    state = AsyncData(newName);
  }
}

@riverpod
class UserAvatarController extends _$UserAvatarController {
  static const _avatarKey = 'user_avatar_path';

  @override
  FutureOr<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey);
  }

  Future<void> updateAvatar(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_avatarKey, path);
    } else {
      await prefs.remove(_avatarKey);
    }
    state = AsyncData(path);
  }
}
