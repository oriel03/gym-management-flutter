import 'package:flutter/material.dart';
import 'package:gym_management_app/utils/breakpoints.dart';

class ComponentResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ComponentResponsive({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder es CRÍTICO: da constraints reales
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Solo construye UNO de los widgets
        if (Breakpoints.isDesktop(width)) {
          return desktop;
        } else if (Breakpoints.isTablet(width)) {
          return tablet ?? desktop; // Fallback a desktop si no hay tablet
        } else {
          return mobile;
        }
      },
    );
  }
}
