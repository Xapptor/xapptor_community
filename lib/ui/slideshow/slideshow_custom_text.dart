import 'package:flutter/material.dart';

Widget slideshow_custom_text(
  String text, {
  required CustomTextType type,
  required bool portrait,
}) {
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
