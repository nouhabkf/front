import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Raccourcis Volume+ : réservé Android ; no-op tant que le canal natif n’est pas branché.
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

  static bool get isIOSPlatform => Platform.isIOS;
  static ValueListenable<bool> get shortcutActiveListenable =>
      _shortcutActiveListenable;

  static void ensureInitialized() {
    if (!Platform.isAndroid) return;
  }

  /// Déclenche l’action accessibilité "primaire" (Volume+ Android, fallback gestes iOS).
  static Future<void> triggerPrimaryShortcut() async {
    final action = _onVolumeUpPriority;
    if (action == null) return;
    try {
      await action();
    } catch (_) {
      // no-op: un raccourci ne doit jamais faire crasher l'app.
    }
  }
}
