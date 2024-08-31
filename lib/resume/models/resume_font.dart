import 'package:pdf/widgets.dart';

class ResumeFont {
  final String name;
  final Font? base;
  final Font? bold;
  final String google_font_family;

  const ResumeFont({
    required this.name,
    required this.base,
    required this.bold,
    required this.google_font_family,
  });

  factory ResumeFont.empty() {
    return const ResumeFont(
      name: '',
      base: null,
      bold: null,
      google_font_family: '',
    );
  }
}
