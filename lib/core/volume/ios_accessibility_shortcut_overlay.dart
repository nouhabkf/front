import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'android_volume_hub.dart';

/// iOS: remplace le raccourci Volume+ par des gestes plein écran.
///
/// - Double tap n'importe où: action principale (équivalent Volume+)
/// - Appui long n'importe où: même action (confirmation/validation)
///
/// L'overlay n'est actif que si un raccourci est enregistré via
/// [AndroidVolumeHub.onVolumeUpPriority].
class IosAccessibilityShortcutOverlay extends StatefulWidget {
  const IosAccessibilityShortcutOverlay({super.key});

  @override
  State<IosAccessibilityShortcutOverlay> createState() =>
      _IosAccessibilityShortcutOverlayState();
}

class _IosAccessibilityShortcutOverlayState
    extends State<IosAccessibilityShortcutOverlay> {
  static const Duration _doubleTapWindow = Duration(milliseconds: 320);
  static const Duration _longPressDuration = Duration(milliseconds: 520);
  static const Duration _debounce = Duration(milliseconds: 850);
  static const double _maxDoubleTapDistance = 48;
  static const double _maxLongPressMove = 18;

  DateTime? _lastTapAt;
  Offset? _lastTapPos;
  DateTime _lastTriggerAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScrollLikeAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _longPressTimer;
  Offset? _pointerDownAt;
  bool _longPressConsumed = false;
  bool _movedTooFar = false;
  bool _wasActive = false;

  void _log(String message) {
    assert(() {
      debugPrint('[IosShortcutOverlay] $message');
      return true;
    }());
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  bool get _activeShortcut =>
      AndroidVolumeHub.isIOSPlatform &&
      AndroidVolumeHub.shortcutActiveListenable.value;

  bool _canTriggerNow() {
    final now = DateTime.now();
    return now.difference(_lastTriggerAt) >= _debounce;
  }

  bool _hasActiveTextInputFocus() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _isScrollLikelyNow() {
    final now = DateTime.now();
    return now.difference(_lastScrollLikeAt) < const Duration(milliseconds: 550);
  }

  bool _shouldIgnoreGesture() {
    if (_isScrollLikelyNow()) return true;
    if (_movedTooFar) return true;
    if (_hasActiveTextInputFocus()) return true;
    return false;
  }

  Future<void> _triggerShortcut() async {
    if (!_canTriggerNow()) return;
    _lastTriggerAt = DateTime.now();
    await AndroidVolumeHub.triggerPrimaryShortcut();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!_activeShortcut) return;
    if (_hasActiveTextInputFocus()) {
      _log('gesture ignored: active text input focus');
      return;
    }
    _pointerDownAt = e.position;
    _longPressConsumed = false;
    _movedTooFar = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDuration, () async {
      if (!_activeShortcut || _pointerDownAt == null) return;
      if (_shouldIgnoreGesture()) {
        _log('long press ignored: scrolling/movement/input detected');
        return;
      }
      _longPressConsumed = true;
      _log('long press triggers shortcut');
      await _triggerShortcut();
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_activeShortcut) return;
    final start = _pointerDownAt;
    if (start == null) return;
    if ((e.position - start).distance > _maxLongPressMove) {
      _movedTooFar = true;
      _lastScrollLikeAt = DateTime.now();
      _log('gesture ignored due to movement/scroll threshold');
      _longPressTimer?.cancel();
    }
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (!_activeShortcut) return;
    _lastScrollLikeAt = DateTime.now();
    _log('gesture ignored due to scroll signal');
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_activeShortcut) return;
    _longPressTimer?.cancel();
    if (_longPressConsumed) {
      _pointerDownAt = null;
      return;
    }

    final now = DateTime.now();
    final isDoubleTap = _lastTapAt != null &&
        now.difference(_lastTapAt!) <= _doubleTapWindow &&
        _lastTapPos != null &&
        (e.position - _lastTapPos!).distance <= _maxDoubleTapDistance;

    if (isDoubleTap) {
      if (_shouldIgnoreGesture()) {
        _log('double tap ignored: scrolling/movement/input detected');
        _lastTapAt = null;
        _lastTapPos = null;
        _pointerDownAt = null;
        _movedTooFar = false;
        return;
      }
      _log('double tap triggers shortcut');
      unawaited(_triggerShortcut());
      _lastTapAt = null;
      _lastTapPos = null;
    } else {
      _lastTapAt = now;
      _lastTapPos = e.position;
    }
    _pointerDownAt = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!AndroidVolumeHub.isIOSPlatform) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: AndroidVolumeHub.shortcutActiveListenable,
      builder: (_, active, child) {
        if (active != _wasActive) {
          _wasActive = active;
          _log('overlay active state: $active');
        }
        if (!active) return const SizedBox.shrink();
        return Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: (_) {
              _longPressTimer?.cancel();
              _pointerDownAt = null;
              _movedTooFar = false;
            },
            onPointerSignal: _onPointerSignal,
          ),
        );
      },
    );
  }
}
