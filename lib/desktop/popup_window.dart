import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const Size kDesktopWindowSize = Size(510, 435);
const Size kDesktopPopupWindowSize = Size(510, 600);

bool get isDesktopWindow =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Captured on the first [prepareDesktopWindowForPopup] of a popup cycle.
/// `prepare`/`restore` can run twice (host + dialog), so only the first
/// visibility check is kept.
bool? _wasHiddenBeforePopup;

Future<bool> _isHiddenOrMinimized() async {
  if (!await windowManager.isVisible()) return true;
  return windowManager.isMinimized();
}

/// Shows a tray-hidden window so Flutter can receive clicks again.
///
/// Close-to-tray uses `SW_HIDE`. Showing via bitsdojo (or a timer) can make
/// the window visible without activating it, so pointer events never reach
/// widgets like ACEITAR.
Future<void> prepareDesktopWindowForPopup() async {
  if (!isDesktopWindow) return;
  try {
    _wasHiddenBeforePopup ??= await _isHiddenOrMinimized();
    await windowManager.show();
    await windowManager.restore();
    await windowManager.setSkipTaskbar(false);
    await windowManager.setSize(kDesktopPopupWindowSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  } catch (_) {}
}

Future<void> restoreDesktopWindowAfterPopup() async {
  if (!isDesktopWindow) return;
  try {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(kDesktopWindowSize);
    if (_wasHiddenBeforePopup == true) {
      await windowManager.hide();
    }
    _wasHiddenBeforePopup = null;
  } catch (_) {}
}
