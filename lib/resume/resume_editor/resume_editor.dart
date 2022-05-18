import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart' as ResumeData;
import 'package:xapptor_community/resume/resume.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:xapptor_ui/widgets/topbar.dart';

class ResumeEditor extends StatefulWidget {
  const ResumeEditor({
    required this.color_topbar,
  });

  final Color color_topbar;

  @override
  _ResumeEditorState createState() => _ResumeEditorState();
}

class _ResumeEditorState extends State<ResumeEditor> {
  TextEditingController name_input_controller = TextEditingController();
  TextEditingController job_title_input_controller = TextEditingController();
  TextEditingController email_input_controller = TextEditingController();
  TextEditingController website_input_controller = TextEditingController();
  TextEditingController profile_input_controller = TextEditingController();

  double screen_height = 0;
  double screen_width = 0;

  TranslationTextListArray text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Fullname",
          "Job Title",
          "Email",
          "Website Url",
          "Dexterity Points",
          "Profile",
          "Employment History",
          "Present",
          "Education",
          "Technologies",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Nombre Completo",
          "Puesto de Trabajo",
          "Correo Electrónico",
          "Página Web",
          "Puntos de Destreza",
          "Perfil",
          "Historial de Empleo",
          "Presente",
          "Educación",
          "Tecnologías",
        ],
      ),
    ],
  );

  late TranslationStream translation_stream;
  List<TranslationStream> translation_stream_list = [];

  int source_language_index = 1;

  update_source_language({
    required int new_source_language_index,
  }) {
    source_language_index = new_source_language_index;
    setState(() {});
  }

  update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    text_list.get(source_language_index)[index] = new_text;
    setState(() {});
  }

  Color text_color = Colors.black;

  @override
  void initState() {
    super.initState();

    translation_stream = TranslationStream(
      translation_text_list_array: text_list,
      update_text_list_function: update_text_list,
      list_index: 0,
      source_language_index: source_language_index,
    );

    translation_stream_list = [translation_stream];
  }

  @override
  Widget build(BuildContext context) {
    screen_height = MediaQuery.of(context).size.height;
    screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    return Scaffold(
      appBar: TopBar(
        background_color: widget.color_topbar,
        has_back_button: true,
        actions: [
          Container(
            width: 150,
            child: LanguagePicker(
              translation_stream_list: translation_stream_list,
              language_picker_items_text_color: widget.color_topbar,
              update_source_language: update_source_language,
            ),
          ),
        ],
        custom_leading: null,
        logo_path: "assets/images/logo.png",
      ),
      body: Container(
        color: Colors.white,
        width: double.maxFinite,
        child: ListView(
          children: [
            FractionallySizedBox(
              widthFactor: portrait ? 0.9 : 0.4,
              child: Column(
                children: [
                  SizedBox(
                    height: sized_box_space,
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: text_color,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[0],
                      labelStyle: TextStyle(
                        color: text_color,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: text_color,
                        ),
                      ),
                    ),
                    controller: name_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.name,
                    ).validate(),
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: text_color,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[1],
                      labelStyle: TextStyle(
                        color: text_color,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: text_color,
                        ),
                      ),
                    ),
                    controller: job_title_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.name,
                    ).validate(),
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: text_color,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[2],
                      labelStyle: TextStyle(
                        color: text_color,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: text_color,
                        ),
                      ),
                    ),
                    controller: email_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.email,
                    ).validate(),
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: text_color,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[3],
                      labelStyle: TextStyle(
                        color: text_color,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: text_color,
                        ),
                      ),
                    ),
                    controller: website_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.email,
                    ).validate(),
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: text_color,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[5],
                      labelStyle: TextStyle(
                        color: text_color,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: text_color,
                        ),
                      ),
                    ),
                    controller: profile_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.email,
                    ).validate(),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                ),
              ),
              child: Resume(
                resume: generate_resume(),
                language_code:
                    text_list.list[source_language_index].source_language,
                text_list: [text_list.get(source_language_index)[7]],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ResumeData.Resume generate_resume() {
    return ResumeData.Resume(
      image_src: "",
      name: name_input_controller.text,
      job_title: job_title_input_controller.text,
      email: email_input_controller.text,
      url: website_input_controller.text,
      skills_title: text_list.get(source_language_index)[4],
      skills: [
        ResumeSkill(
          name: "Experience: 5 years",
          percentage: 0.5,
          color: Colors.blue,
        ),
        ResumeSkill(
          name: "Communication",
          percentage: 0.8,
          color: Colors.blue,
        ),
        ResumeSkill(
          name: "Cognitive Flexibility",
          percentage: 0.8,
          color: Colors.blue,
        ),
        ResumeSkill(
          name: "Negotiation",
          percentage: 0.7,
          color: Colors.blue,
        ),
        ResumeSkill(
          name: "Health",
          percentage: 0.9,
          color: Colors.blue,
        ),
        ResumeSkill(
          name: "Mana",
          percentage: 0.8,
          color: Colors.blue,
        ),
      ],
      sections_lengths: [7, 2],
      sections: [
        ResumeSection(
          icon: Icons.badge,
          code_point: 0xea67,
          title: text_list.get(source_language_index)[5],
          description: profile_input_controller.text,
        ),
        ResumeSection(
          icon: Icons.dvr_rounded,
          code_point: 0xe1b2,
          title: text_list.get(source_language_index)[6],
          subtitle: "Flutter Developer at Wizeline, Remote",
          begin: DateTime(2022, 2),
          end: DateTime.now(),
          description:
              "Design, development and implementation of software in the mobile applications area (Android and IOS). Use of native and cross-platform frameworks such as IOS Native, Kotlin Native, and Flutter. Implementing development methodologies like Safe, Agile and Scrum.",
        ),
        ResumeSection(
          subtitle: "Software Developer at Keydok, Mexico City",
          begin: DateTime(2019, 10),
          end: DateTime(2022, 2),
          description:
              "Design, development and implementation of software in the mobile applications area (Android and IOS). Use of native and cross-platform frameworks such as IOS Native, Kotlin Native, Flutter and Kotlin Multi-platform. Implementing development methodologies like Safe, Agile and Scrum.",
        ),
        ResumeSection(
          subtitle: "Software Developer at Ike Asistencia, Mexico City",
          begin: DateTime(2019, 4),
          end: DateTime(2019, 10),
          description:
              "Design, development and implementation of software in the mobile applications area (Android and IOS). Development of Backend and microservices using Spring Boot and Micronaut framework. Implementing development methodologies like Safe, Agile and Scrum.",
        ),
        ResumeSection(
          subtitle: "Game Developer at Visionaria Games, Mexico City",
          begin: DateTime(2018, 1),
          end: DateTime(2019, 4),
          description:
              "Design, development and implementation of software in the mobile applications area (Android and IOS). Development of video games, and web application Flow package used for the application of artificial intelligence in characters and their behaviors.",
        ),
        ResumeSection(
          subtitle:
              "Software Design Professor at Universidad Mexicana de Innovación en Negocios, Metepec",
          begin: DateTime(2017, 6),
          end: DateTime(2018, 1),
          description:
              "Teaching high school level students on mobile applications and video games.",
        ),
        ResumeSection(
          subtitle: "Freelance Software Developer, Metepec",
          begin: DateTime(2016, 2),
          end: DateTime(2017, 6),
          description:
              "Development of custom software for the administration of scheduled educational events.",
        ),
        ResumeSection(
          icon: Icons.history_edu_rounded,
          code_point: 0xea3e,
          title: "Education",
          subtitle:
              "Digital Business Engineer, Universidad Mexicana de Innovación en Negocios, Metepec",
          begin: DateTime(2014, 7),
          end: DateTime(2018, 7),
        ),
        ResumeSection(
          icon: Icons.bar_chart_rounded,
          code_point: 0xe26b,
          title: "Technologies",
          description:
              "Java, JavaScript, C#, Kotlin, Swift, Dart, Flutter, Android Compose, SwiftUI, Micronaut, NodeJs, Google cloud Platform, Firebase, Mysql, Stripe, Playcanvas, Unity, Unreal Engine.",
        ),
      ],
      icon_color: Colors.blue,
    );
  }
}
