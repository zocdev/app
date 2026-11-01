import 'package:flutter/material.dart';

import 'zoc_tokens.dart';

/// Small pill badge (11.5 w600). [tone] picks soft fill + ink text.
class ZocBadge extends StatelessWidget {
  const ZocBadge(this.label, {super.key, this.tone = ZocTone.brand, this.icon});

  final String label;
  final ZocTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: BorderRadius.circular(ZocRadii.pill),
          border: Border.all(
              color: tone == ZocTone.brand
                  ? ZocColors.brandLine
                  : tone.color.withValues(alpha: .15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: tone.ink),
              const SizedBox(width: 4),
            ],
            Text(label,
                maxLines: 1,
                style: ZocText.caption(color: tone.ink, weight: FontWeight.w600)
                    .copyWith(fontSize: 11.5, height: 1.3)),
          ],
        ),
      );
}

/// Round 64px icon on a soft tint with an 8px halo ring (80px total).
/// [small] = 40px without halo (list / header use).
class ZocHeroIcon extends StatelessWidget {
  const ZocHeroIcon(this.icon,
      {super.key, this.tone = ZocTone.brand, this.small = false});

  final IconData icon;
  final ZocTone tone;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: small ? 40 : 64,
      height: small ? 40 : 64,
      decoration: BoxDecoration(color: tone.soft, shape: BoxShape.circle),
      child: Icon(icon, size: small ? 18 : 28, color: tone.color),
    );
    if (small) return circle;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: .08),
        shape: BoxShape.circle,
      ),
      child: circle,
    );
  }
}

/// 6px rounded progress bar. [value] is clamped to 0..1. [onDark] = white bar
/// on a 20% white track (inside [ZocHeroCard]).
class ZocProgressBar extends StatelessWidget {
  const ZocProgressBar(
      {super.key, required this.value, this.onDark = false, this.height = 6});

  final double value;
  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(ZocRadii.pill),
        child: Container(
          height: height,
          color: onDark ? const Color(0x33FFFFFF) : ZocColors.brandSoft,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.isNaN ? 0 : value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: onDark ? Colors.white : ZocColors.brand,
                borderRadius: BorderRadius.circular(ZocRadii.pill),
              ),
            ),
          ),
        ),
      );
}

/// List row: colored left bar, bold [title], muted [subtitle], [trailing].
/// Pick [barColor] from `ZocColors.accents[i % 4]`.
class ZocListItem extends StatelessWidget {
  const ZocListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.barColor = ZocColors.brand,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? barColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ZocRadii.item);
    return Material(
      color: ZocColors.listFill,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (barColor != null) ...[
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZocText.strong()),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ZocText.caption()),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  Center(child: trailing!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kind of [ZocNotice].
enum ZocNoticeKind { info, warn, error }

/// Inline message box (radius 14, 12.5px) with a leading icon.
class ZocNotice extends StatelessWidget {
  const ZocNotice(this.message,
      {super.key, this.kind = ZocNoticeKind.info, this.icon});

  final String message;
  final ZocNoticeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tone = switch (kind) {
      ZocNoticeKind.info => ZocTone.brand,
      ZocNoticeKind.warn => ZocTone.warn,
      ZocNoticeKind.error => ZocTone.danger,
    };
    final defaultIcon = switch (kind) {
      ZocNoticeKind.info => Icons.info_outline_rounded,
      ZocNoticeKind.warn => Icons.warning_amber_rounded,
      ZocNoticeKind.error => Icons.error_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(ZocRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon ?? defaultIcon, size: 15, color: tone.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: ZocText.caption(color: tone.ink)
                    .copyWith(fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
