// FONT FAMILIES FOR VISUALIZER AND PDF
import 'package:printing/printing.dart';
import 'package:xapptor_community/resume/models/resume_font.dart';

// FONT FAMILIES FOR VISUALIZER AND PDF
Future<List<ResumeFont>> font_families() async => [
      ResumeFont(
        name: 'Nunito',
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoMedium(),
      ),
      ResumeFont(
        name: 'QuickSand',
        base: await PdfGoogleFonts.quicksandRegular(),
        bold: await PdfGoogleFonts.quicksandMedium(),
      ),
      ResumeFont(
        name: 'Ubuntu',
        base: await PdfGoogleFonts.ubuntuRegular(),
        bold: await PdfGoogleFonts.ubuntuMedium(),
      ),
      ResumeFont(
        name: 'Lexend',
        base: await PdfGoogleFonts.lexendRegular(),
        bold: await PdfGoogleFonts.lexendMedium(),
      ),
      ResumeFont(
        name: 'Roboto',
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoMedium(),
      ),
      ResumeFont(
        name: 'OpenSans',
        base: await PdfGoogleFonts.openSansRegular(),
        bold: await PdfGoogleFonts.openSansMedium(),
      ),
      ResumeFont(
        name: 'Montserrat',
        base: await PdfGoogleFonts.montserratRegular(),
        bold: await PdfGoogleFonts.montserratMedium(),
      ),
    ];

Future<ResumeFont> current_font() async => (await font_families())[0];
// FONT FAMILIES FOR VISUALIZER AND PDF

// FONT SIZES FOR VISUALIZER AND PDF
double font_size_name = 13;
double font_size_job_title = 12;
double font_size_website_url = 9;

double font_size_skills_title = 10;
double font_size_skill = 9;

double font_size_section_title = 11;
double font_size_section_subtitle = 10;
double font_size_section_description = 9;
double font_size_section_timeframe = 8;

double font_size_info_title = 9;
double font_size_info_url = 9;
// FONT SIZES FOR VISUALIZER AND PDF
