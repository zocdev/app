import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZocLogo extends StatelessWidget {
  const ZocLogo({
    super.key,
    this.width = 100.0,
    this.showTagline = false,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final bool showTagline;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = (!showTagline && width > 130.0) ? 100.0 : width;
    final wordmarkHeight = effectiveWidth * (174.0 / 557.0);

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: effectiveWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/ZOC.png',
              width: effectiveWidth,
              height: wordmarkHeight,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.high,
            ),
            if (showTagline) ...[
              const SizedBox(height: 6.0),
              Text(
                'Granular Profitability. In Real Time.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF101827),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
