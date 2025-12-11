import 'package:flutter/material.dart';

Widget slideshow_custom_text(
  String text, {
  required CustomTextType type,
  required bool portrait,
  TextStyle? custom_title_style,
  TextStyle? custom_subtitle_style,
  TextStyle? custom_body_style,
}) {
  // Use custom styles if provided, otherwise fall back to defaults
  TextStyle? custom_style;
  switch (type) {
    case CustomTextType.title:
      custom_style = custom_title_style;
      break;
    case CustomTextType.subtitle:
      custom_style = custom_subtitle_style;
      break;
    case CustomTextType.body:
      custom_style = custom_body_style;
      break;
  }

  if (custom_style != null) {
    // Adjust font size for portrait/landscape if using custom style
    final double size_multiplier = portrait ? 0.6 : 1.4;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: custom_style.copyWith(
        fontSize: (custom_style.fontSize ?? 16) * size_multiplier,
      ),
    );
  }

  // Default style (legacy behavior)
  double font_size = 16;

  switch (type) {
    case CustomTextType.title:
      font_size = portrait ? 26 : 50;
      break;
    case CustomTextType.subtitle:
      font_size = portrait ? 20 : 36;
      break;
    case CustomTextType.body:
      font_size = portrait ? 16 : 24;
      break;
  }

  return Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: font_size,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: const [
        Shadow(
          blurRadius: 40,
          color: Colors.black,
          offset: Offset(2, 2),
        ),
        Shadow(
          blurRadius: 10,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    ),
  );
}

enum CustomTextType {
  title,
  subtitle,
  body,
}
