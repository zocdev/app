import 'package:flutter/material.dart';

import 'zoc_tokens.dart';

/// Soft window background: teal glow from the top-right, warm glow from the
/// bottom-left, over [ZocColors.background]. Fills its parent.
class ZocBackground extends StatelessWidget {
  const ZocBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _BackgroundPainter(), child: child);
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ZocColors.background);
    // CSS: radial-gradient(120% 80% at 100% 0%, #D3EEEC 0%, transparent 55%)
    _glow(canvas, size, Offset(size.width, 0), 1.2, 0.8,
        const Color(0xFFD3EEEC), 0.55);
    // CSS: radial-gradient(90% 70% at 0% 100%, #FFF4DF 0%, transparent 60%)
    _glow(canvas, size, Offset(0, size.height), 0.9, 0.7,
        const Color(0xFFFFF4DF), 0.6);
  }

  void _glow(Canvas canvas, Size size, Offset c, double fx, double fy,
      Color color, double stop) {
    final rx = size.width * fx, ry = size.height * fy;
    if (rx <= 0 || ry <= 0) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(rx, ry);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
        stops: [0, stop],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    canvas.drawRect(
        Rect.fromLTRB(-c.dx / rx, -c.dy / ry, (size.width - c.dx) / rx,
            (size.height - c.dy) / ry),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ZOC wordmark, 22px tall.
class ZocWordmark extends StatelessWidget {
  const ZocWordmark({super.key, this.height = 22});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/ZOC_wordmark.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'ZOC',
      );
}

/// Layout for auth / tray screens (fits 510×435): background, logo top-left,
/// optional [topAction] top-right, [body] centered (inside a [ZocPanel] when
/// [panel] is true) and an optional [footer] (usually [ZocDisclaimer]).
/// Scrolls instead of overflowing when content is taller than the window.
/// [center] limits the panel to 400 wide (success / info screens); center the
/// body's own content with `CrossAxisAlignment.center` / `ZocTitle(center:)`.
class ZocAuthScaffold extends StatelessWidget {
  const ZocAuthScaffold({
    super.key,
    required this.body,
    this.topAction,
    this.footer,
    this.panel = true,
    this.center = false,
    this.panelPadding,
    this.scaffoldKey,
  });

  final Widget body;
  final Widget? topAction;
  final Widget? footer;
  final bool panel;
  final bool center;
  final EdgeInsetsGeometry? panelPadding;
  final Key? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (panel) {
      content = ZocPanel(padding: panelPadding, child: content);
    }
    if (center) {
      content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400), child: content);
    }
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: ZocColors.background,
      body: ZocBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Row(
                  children: [
                    const ZocWordmark(),
                    const Spacer(),
                    if (topAction != null) topAction!,
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: (c.maxHeight - 20).clamp(0, 1e9)),
                      child: Center(child: content),
                    ),
                  ),
                ),
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Big floating white surface (radius 24, padding 22/24, panel shadow).
class ZocPanel extends StatelessWidget {
  const ZocPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: ZocColors.surface,
          borderRadius: BorderRadius.circular(ZocRadii.panel),
          boxShadow: ZocShadows.panel,
        ),
        child: child,
      );
}

/// Small floating white card (radius 22, soft teal shadow, no border).
class ZocCard extends StatelessWidget {
  const ZocCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = ZocColors.surface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ZocRadii.card);
    return DecoratedBox(
      decoration: BoxDecoration(
          color: color, borderRadius: radius, boxShadow: ZocShadows.card),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Teal gradient stat card with a soft decorative circle. Text and icons
/// inside default to white. Use [ZocProgressBar] with `onDark: true`.
class ZocHeroCard extends StatelessWidget {
  const ZocHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.radius = ZocRadii.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: ZocGradients.hero),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                ),
              ),
              Padding(
                padding: padding,
                child: IconTheme.merge(
                  data: const IconThemeData(color: Color(0xD9FFFFFF)),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Dialog surface (radius 28, padding 28, max width [width]). Use with
/// [showZocModal] or inside your own `Dialog`.
class ZocModal extends StatelessWidget {
  const ZocModal({
    super.key,
    required this.child,
    this.width = 380,
    this.padding = const EdgeInsets.all(28),
  });

  final Widget child;
  final double width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ZocColors.surface,
                borderRadius: BorderRadius.circular(ZocRadii.modal),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x2E101827),
                      offset: Offset(0, 12),
                      blurRadius: 32,
                      spreadRadius: -8),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(ZocRadii.modal),
                clipBehavior: Clip.antiAlias,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      );
}

/// Shows [child] (usually a [ZocModal]) as a dialog over the ZOC scrim.
Future<T?> showZocModal<T>(BuildContext context,
        {required WidgetBuilder builder, bool barrierDismissible = true}) =>
    showDialog<T>(
      context: context,
      barrierColor: ZocColors.scrim,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );

/// Title + subtitle block. [badge] goes above the title. [subtitle] may be a
/// String or use [subtitleWidget] for rich text. [small] uses the h2 size.
class ZocTitle extends StatelessWidget {
  const ZocTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.subtitleWidget,
    this.badge,
    this.center = false,
    this.small = false,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? badge;
  final bool center;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[badge!, const SizedBox(height: 6)],
        Text(title,
            textAlign: align, style: small ? ZocText.h2() : ZocText.title()),
        if (subtitle != null || subtitleWidget != null) ...[
          const SizedBox(height: 6),
          subtitleWidget ??
              Text(subtitle!, textAlign: align, style: ZocText.sub()),
        ],
      ],
    );
  }
}

/// Legal disclaimer shown at the bottom of auth screens (10px faint).
/// Defaults to the short copy of the approved mockups; pass
/// `DisclaimerBanner.message` for the long legal text.
class ZocDisclaimer extends StatelessWidget {
  const ZocDisclaimer({super.key, this.text = shortMessage});

  /// Short disclaimer copy from the option B mockups.
  static const shortMessage =
      'O ZOC é uma ferramenta de referência financeira e de gestão. Os valores '
      'e relatórios não constituem folha de pagamento ou documento com '
      'validade legal.';

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: ZocText.caption(color: ZocColors.faint)
              .copyWith(fontSize: 10, height: 1.45),
        ),
      );
}
