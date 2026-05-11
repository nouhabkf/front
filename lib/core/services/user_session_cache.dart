import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../utils/storage_keys.dart';

/// Cache local du profil pour garder la session après reload si `/user/me` échoue (réseau).
class UserSessionCache {
  UserSessionCache._();

  static Future<void> save(UserModel user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      StorageKeys.cachedUserJson,
      jsonEncode(user.toJson()),
    );
  }

  static Future<UserModel?> read() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(StorageKeys.cachedUserJson);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.cachedUserJson);
  }
}
