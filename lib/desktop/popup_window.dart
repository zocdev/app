import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const Size kDesktopWindowSize = Size(510, 435);
const Size kDesktopPopupWindowSize = Size(510, 600);

bool get isDesktopWindow =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Shows a tray-hidden window so Flutter can receive clicks again.
///
/// Close-to-tray uses `SW_HIDE`. Showing via bitsdojo (or a timer) can make
/// the window visible without activating it, so pointer events never reach
/// widgets like ACEITAR.
Future<void> prepareDesktopWindowForPopup() async {
  if (!isDesktopWindow) return;
  try {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.setSkipTaskbar(false);
    await windowManager.setSize(kDesktopPopupWindowSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  } catch (_) {}
}

/// Sends the window back to the tray once the popup closes, so answering it
/// never leaves the main (Registro) screen on top of the user's work.
/// macOS has no tray icon, so it minimizes to the Dock instead.
Future<void> restoreDesktopWindowAfterPopup() async {
  if (!isDesktopWindow) return;
  try {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(kDesktopWindowSize);
    await hideDesktopWindow();
  } catch (_) {}
}

/// Windows hides to the tray. macOS has no tray icon (see main.dart), so a
/// hidden window could never be reopened: minimize to the Dock instead.
Future<void> hideDesktopWindow() async {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    await windowManager.minimize();
  } else {
    await windowManager.hide();
  }
}
