import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';

class AppAnimatedBackground extends StatelessWidget {
  final Widget child;

  const AppAnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // :fire: FONDO GLOBAL usando AppColors (CORRECTO)
        Positioned.fill(
          child: Container(
            color: AppColors.backgroundLight, // :point_left: ahora usa tu sistema centralizado
          ),
        ),

        // CONTENIDO
        child,
      ],
    );
  }
}