import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'zoc_controls.dart';
import 'zoc_tokens.dart';

/// App-wide Material theme matching the kit, so plain Material widgets
/// (TextButton, ElevatedButton, TextField, Checkbox, Switch, dialogs) look
/// close to the kit even before a screen is restyled.
ThemeData zocThemeData() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false,
    primaryColor: ZocColors.brand,
    colorScheme: const ColorScheme.light(
      primary: ZocColors.brand,
      secondary: ZocColors.brand,
      error: ZocColors.bad,
      surface: ZocColors.surface,
    ),
  );
  const pill = WidgetStatePropertyAll(StadiumBorder());
  final label = WidgetStatePropertyAll(ZocText.button());
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    iconTheme: const IconThemeData(color: ZocColors.brand),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: ZocColors.brand),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ZocColors.brand,
      selectionColor: ZocColors.brandLine,
      selectionHandleColor: ZocColors.brand,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ZocColors.brand)
          .copyWith(shape: pill, textStyle: label),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ZocColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: ZocColors.brand.withValues(alpha: .45),
        disabledForegroundColor: Colors.white.withValues(alpha: .8),
        elevation: 0,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ).copyWith(shape: pill, textStyle: label),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ZocColors.brand,
        side: const BorderSide(color: ZocColors.brand),
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ).copyWith(shape: pill, textStyle: label),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ZocColors.inputFill,
      hintStyle: ZocText.body(color: ZocColors.faint),
      errorStyle: ZocText.caption(color: ZocColors.bad),
      border: ZocInputBorder.idle,
      enabledBorder: ZocInputBorder.idle,
      disabledBorder: ZocInputBorder.idle,
      focusedBorder: ZocInputBorder.focused,
      errorBorder: ZocInputBorder.error,
      focusedErrorBorder: ZocInputBorder.focusedError,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ZocColors.brand : null),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: ZocColors.control, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? ZocColors.brand
              : ZocColors.control),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ZocColors.surface,
      barrierColor: ZocColors.scrim,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZocRadii.modal)),
      titleTextStyle: ZocText.h2(),
      contentTextStyle: ZocText.sub(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ZocColors.text,
      contentTextStyle: ZocText.body(color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZocRadii.input)),
    ),
  );
}
