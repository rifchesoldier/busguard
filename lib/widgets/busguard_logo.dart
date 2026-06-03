import 'package:flutter/material.dart';
import '../utils/theme.dart';

class BusGuardLogo extends StatelessWidget {
  final double size;
  const BusGuardLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Icon(Icons.directions_bus,
          size: size * 0.6, color: AppColors.navy),
    );
  }
}
