import 'package:flutter/material.dart';

class ResponsiveUtils {
  static ResponsiveData of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ResponsiveData(size);
  }
}

class ResponsiveData {
  final Size screenSize;

  ResponsiveData(this.screenSize);

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // ASEGÚRATE QUE ESTE GETTER ESTÉ AQUÍ
  EdgeInsetsDirectional get padding => EdgeInsetsDirectional.symmetric(
    horizontal:
        isMobile
            ? screenWidth * 0.04
            : isTablet
            ? screenWidth * 0.03
            : screenWidth * 0.02,
  );

  EdgeInsetsDirectional get contentPadding => EdgeInsetsDirectional.symmetric(
    horizontal: isMobile ? screenWidth * 0.03 : screenWidth * 0.02,
    vertical: screenHeight * 0.015,
  );

  double get fontSize => (isMobile
          ? screenWidth * 0.045
          : isTablet
          ? screenWidth * 0.025
          : 18.0)
      .clamp(14.0, 24.0);

  double get borderRadius => (isMobile
          ? screenWidth * 0.04
          : isTablet
          ? screenWidth * 0.02
          : 12.0)
      .clamp(8.0, 20.0);
}
