import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Widget? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final FontStyle? fontStyle;
  final double elevation;
  final Border? border;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double iconSpacing;
  final bool isResponsive;
  final int maxLines;
  final TextOverflow overflow;

  const CustomButton({
    super.key,
    required this.onPressed,
    this.text = '',
    this.backgroundColor = const Color(0xFF53AA70),
    this.textColor = const Color(0xFF2C3232),
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.contentPadding,
    this.borderRadius = 8.0,
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.fontStyle,
    this.elevation = 2.0,
    this.border,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.iconSpacing = 8.0,
    this.isResponsive = true,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  // Factory constructors para casos comunes (opcionales)

  /// Botón primario estándar
  factory CustomButton.primary({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    Widget? icon,
    FontWeight? fontWeight,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      backgroundColor: backgroundColor ?? const Color(0xFF53AA70),
      textColor: textColor ?? Colors.white,
      fontWeight: FontWeight.normal,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  /// Botón secundario con borde
  factory CustomButton.secondary({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    Widget? icon,
    Color? borderColor,
    Color? textColor,
  }) {
    final color = borderColor ?? const Color(0xFF53AA70);
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      backgroundColor: Colors.transparent,
      textColor: textColor ?? color,
      border: Border.all(color: color, width: 2),
      elevation: 0,
      fontWeight: FontWeight.normal,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    );
  }

  /// Botón solo con ícono
  factory CustomButton.iconOnly({
    Key? key,
    required VoidCallback onPressed,
    required Widget icon,
    Color? backgroundColor,
    double? size,
    double? borderRadius,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor ?? const Color(0xFF53AA70),
      width: size ?? 48,
      height: size ?? 48,
      borderRadius: borderRadius ?? 24,
      contentPadding: EdgeInsets.zero,
      isResponsive: false,
    );
  }

  /// Botón de texto simple
  factory CustomButton.text({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    Color? textColor,
    double? fontSize,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      backgroundColor: Colors.transparent,
      textColor: textColor ?? const Color(0xFF53AA70),
      elevation: 0,
      fontWeight: FontWeight.normal,
      fontSize: fontSize ?? 14,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }

  /// Botón con ícono a la izquierda (personalizable)
  factory CustomButton.withIcon({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    required Widget icon,
    required FontWeight fontWeight,
    Color? backgroundColor,
    Color? textColor,
    double? iconSpacing,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      backgroundColor: backgroundColor ?? const Color(0xFF53AA70),
      textColor: textColor ?? Colors.white,
      iconSpacing: iconSpacing ?? 4.0,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      fontWeight: FontWeight.w600,
    );
  }

  /// Botón de peligro/eliminación
  factory CustomButton.danger({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    Widget? icon,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontWeight: FontWeight.w600,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = isResponsive && screenWidth < 600;

    // Padding por defecto basado en responsive
    final effectivePadding =
        padding ??
        (isMobile
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.symmetric(horizontal: 24));

    // Content padding por defecto
    final effectiveContentPadding =
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    return Container(
      width: width ?? (isMobile ? double.infinity : null),
      height: height,
      padding: effectivePadding,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: effectiveContentPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: border != null ? border!.top : BorderSide.none,
          ),
          elevation: elevation,
          shadowColor: Colors.black26,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: [
            if (icon != null) ...[
              icon!,
              if (text.isNotEmpty) SizedBox(width: iconSpacing),
            ],
            if (text.isNotEmpty)
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  overflow: overflow,
                  maxLines: maxLines,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    fontFamily: fontFamily,
                    fontStyle: fontStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
