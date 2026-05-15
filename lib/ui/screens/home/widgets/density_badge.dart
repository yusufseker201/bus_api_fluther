import 'package:flutter/material.dart';

import '../../../../models/density_level.dart';

class DensityBadge extends StatelessWidget {
  const DensityBadge({super.key, required this.level});

  final DensityLevel level;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.labelTr,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  (Color, Color) _colors(DensityLevel level) {
    return switch (level) {
      DensityLevel.green => (const Color(0xFFE6F7EE), const Color(0xFF0F7A3D)),
      DensityLevel.yellow => (const Color(0xFFFFF7DF), const Color(0xFF7A5A00)),
      DensityLevel.red => (const Color(0xFFFFE7E7), const Color(0xFFB00020)),
      DensityLevel.black => (const Color(0xFF1F2937), const Color(0xFFFFFFFF)),
    };
  }
}

