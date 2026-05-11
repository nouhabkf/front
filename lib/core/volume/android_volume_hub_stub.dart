import 'package:flutter/foundation.dart';

/// Raccourcis Volume+ (Android) — version sans `dart:io` (web / analyse).
class AndroidVolumeHub {
  AndroidVolumeHub._();

  static final ValueNotifier<bool> _shortcutActiveListenable =
      ValueNotifier<bool>(false);
  static Future<bool> Function()? _onVolumeUpPriority;

  static Future<bool> Function()? get onVolumeUpPriority => _onVolumeUpPriority;
  static set onVolumeUpPriority(Future<bool> Function()? value) {
    _onVolumeUpPriority = value;
    _shortcutActiveListenable.value = value != null;
  }

  static bool get isIOSPlatform => false;
  static ValueListenable<bool> get shortcutActiveListenable =>
      _shortcutActiveListenable;

  static void ensureInitialized() {}

  static Future<void> triggerPrimaryShortcut() async {
    final action = _onVolumeUpPriority;
    if (action == null) return;
    try {
      await action();
    } catch (_) {
      // no-op
    }
  }
}
