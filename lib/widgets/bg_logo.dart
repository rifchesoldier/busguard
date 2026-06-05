import 'package:flutter/material.dart';
import '../core/theme.dart';

class BgLogo extends StatelessWidget {
  final double size;
  final bool light;

  const BgLogo({super.key, this.size = 64, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BgColors.gold, BgColors.terracotta],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: BgColors.terracotta.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.directions_bus_rounded,
        color: light ? Colors.white : BgColors.ink,
        size: size * 0.5,
      ),
    );
  }
}
