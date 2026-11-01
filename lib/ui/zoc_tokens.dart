import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color tokens of the "Suave" (option B) design. Never hard-code these
/// values in screens; use `ZocColors.x` instead.
abstract final class ZocColors {
  static const brand = Color(0xFF0F8F8A);
  static const brandInk = Color(0xFF0B6F6B);
  static const brandSoft = Color(0xFFE6F4F3);

  /// Brand at 15% (badge borders, focus glow).
  static const brandLine = Color(0x260F8F8A);

  static const text = Color(0xFF101827);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const line = Color(0xFFE7EEF0);

  static const surface = Colors.white;

  /// Fill of toggle rows, doc links, info steps.
  static const surface2 = Color(0xFFF3F7F7);

  /// Fill of list items.
  static const listFill = Color(0xFFF5F8F9);

  /// Fill of inputs and selects.
  static const inputFill = Color(0xFFF3F6F8);

  /// Base color of the window background (under the gradients).
  static const background = Color(0xFFF4F8F8);

  static const ok = Color(0xFF16A34A);
  static const okSoft = Color(0xFFDCFCE7);
  static const warn = Color(0xFFD97706);
  static const warnSoft = Color(0xFFFEF3C7);
  static const warnInk = Color(0xFF92400E);

  /// Light amber surface for warning stat cards.
  static const warnSurface = Color(0xFFFFF7E8);
  static const bad = Color(0xFFDC2626);
  static const badSoft = Color(0xFFFEE2E2);
  static const badInk = Color(0xFFB91C1C);

  /// Time past the goal. Brighter than [bad] so it reads on the teal hero.
  static const overtime = Color(0xFFFF4D4F);

  /// Off track of switches and empty checkbox border.
  static const control = Color(0xFFCBD5E1);

  /// Modal barrier (text at 45%).
  static const scrim = Color(0x73101827);

  /// Accent colors for list item bars (cycle by index).
  static const accents = [
    brand,
    Color(0xFF2FA3D3),
    Color(0xFFF5A524),
    Color(0xFF8B5CF6)
  ];
}

/// Corner radii.
abstract final class ZocRadii {
  static const double input = 14;
  static const double item = 16;
  static const double heroInner = 18;
  static const double card = 22;
  static const double panel = 24;
  static const double modal = 28;
  static const double pill = 999;
}

/// Shadows.
abstract final class ZocShadows {
  /// Large floating panels (auth panel, modals).
  static const panel = [
    BoxShadow(
        color: Color(0x40101827),
        offset: Offset(0, 20),
        blurRadius: 40,
        spreadRadius: -20),
  ];

  /// Small cards, segmented control, icon buttons.
  static const card = [
    BoxShadow(color: Color(0x0A101827), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
        color: Color(0x400F8F8A),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -12),
  ];

  /// Primary button.
  static const button = [
    BoxShadow(color: Color(0x4D0F8F8A), offset: Offset(0, 1), blurRadius: 2),
  ];
}

/// Gradients.
abstract final class ZocGradients {
  /// Teal hero gradient (stat cards, live tracking block).
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ZocColors.brand, ZocColors.brandInk, Color(0xFF12807C)],
    stops: [0, 0.6, 1],
  );
}

/// Inter text styles. Pass `color:` to override.
abstract final class ZocText {
  static TextStyle _inter(double size, FontWeight weight, Color color,
          {double? height, double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing);

  /// Screen title (h1): 22 w700, -0.02em.
  static TextStyle title({Color color = ZocColors.text}) =>
      _inter(22, FontWeight.w700, color, height: 1.2, letterSpacing: -0.44);

  /// Section / modal title (h2): 18 w700.
  static TextStyle h2({Color color = ZocColors.text}) =>
      _inter(18, FontWeight.w700, color, height: 1.25, letterSpacing: -0.18);

  /// Card title (h3): 15 w700.
  static TextStyle h3({Color color = ZocColors.text}) =>
      _inter(15, FontWeight.w700, color, height: 1.3);

  /// Subtitle under titles: 13.5 muted, line-height 1.5.
  static TextStyle sub({Color color = ZocColors.muted}) =>
      _inter(13.5, FontWeight.w400, color, height: 1.5);

  /// Body text: 14.
  static TextStyle body(
          {Color color = ZocColors.text,
          FontWeight weight = FontWeight.w400}) =>
      _inter(14, weight, color, height: 1.4);

  /// Bold row title (toggle rows, list items): 13.5 w600.
  static TextStyle strong({Color color = ZocColors.text}) =>
      _inter(13.5, FontWeight.w600, color, height: 1.3);

  /// Field label: 12 w600.
  static TextStyle label({Color color = ZocColors.text}) =>
      _inter(12, FontWeight.w600, color, height: 1.25);

  /// Help / caption text: 12 muted.
  static TextStyle caption(
          {Color color = ZocColors.muted,
          FontWeight weight = FontWeight.w400}) =>
      _inter(12, weight, color, height: 1.35);

  /// Button label: 14 w600 (small: 13).
  static TextStyle button({Color color = Colors.white, double size = 14}) =>
      _inter(size, FontWeight.w600, color, height: 1.2);

  /// Big number (hours): 30 w700, -0.03em.
  static TextStyle big({Color color = ZocColors.text}) =>
      _inter(30, FontWeight.w700, color, height: 1.15, letterSpacing: -0.9);

  /// Link text: 13 w600 brand.
  static TextStyle link({Color color = ZocColors.brand}) =>
      _inter(13, FontWeight.w600, color, height: 1.3);
}

/// Semantic tone used by badges, hero icons and notices.
enum ZocTone { brand, success, warn, danger, neutral }

extension ZocToneColors on ZocTone {
  /// Strong color (icon, text on soft fill).
  Color get color => switch (this) {
        ZocTone.brand => ZocColors.brand,
        ZocTone.success => ZocColors.ok,
        ZocTone.warn => ZocColors.warn,
        ZocTone.danger => ZocColors.bad,
        ZocTone.neutral => ZocColors.muted,
      };

  /// Darker text color for use on [soft].
  Color get ink => switch (this) {
        ZocTone.brand => ZocColors.brandInk,
        ZocTone.success => const Color(0xFF15803D),
        ZocTone.warn => ZocColors.warnInk,
        ZocTone.danger => ZocColors.badInk,
        ZocTone.neutral => ZocColors.muted,
      };

  /// Soft fill.
  Color get soft => switch (this) {
        ZocTone.brand => ZocColors.brandSoft,
        ZocTone.success => ZocColors.okSoft,
        ZocTone.warn => ZocColors.warnSoft,
        ZocTone.danger => ZocColors.badSoft,
        ZocTone.neutral => ZocColors.surface2,
      };
}
