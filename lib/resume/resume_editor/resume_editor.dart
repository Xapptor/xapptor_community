import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/check_for_remote_resume.dart';
import 'package:xapptor_community/resume/resume_editor/generate_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_fab.dart';
import 'package:xapptor_community/resume/resume_visualizer/resume_visualizer.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_logic/check_browser_type.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:xapptor_ui/widgets/topbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

class ResumeEditor extends StatefulWidget {
  final Color color_topbar;
  final String base_url;
  final double text_bottom_margin_for_section;

  const ResumeEditor({
    super.key,
    required this.color_topbar,
    required this.base_url,
    this.text_bottom_margin_for_section = 3,
  });

  @override
  State<ResumeEditor> createState() => ResumeEditorState();
}

class ResumeEditorState extends State<ResumeEditor> {
  TextEditingController name_input_controller = TextEditingController();
  TextEditingController job_title_input_controller = TextEditingController();
  TextEditingController email_input_controller = TextEditingController();
  TextEditingController website_input_controller = TextEditingController();
  TextEditingController profile_input_controller = TextEditingController();
  TextEditingController sections_by_page_input_controller = TextEditingController();

  double screen_height = 0;
  double screen_width = 0;

  TranslationTextListArray text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Full Name",
          "Job Title",
          "Email",
          "Website Url",
          "Dexterity Points",
          "Profile",
          "Resume Preview",
          "Employment History",
          "Title",
          "Subtitle",
          "Description",
          "Present",
          "Choose Dates",
          "Choose initial date",
          "Choose end date",
          "Education",
          "Custom Sections",
          "Before adding a new section you must first complete the last one",
          "Resume available online at:",
          "Resume Developed and Hosted by American Business Excellence Institute:",
          "Use Example Resume",
          "Resume Saved",
          "Download",
          "Save",
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
          "Vista Previa del CV",
          "Historial de Empleo",
          "Título",
          "Subtítulo",
          "Descripción",
          "Presente",
          "Seleccionar Fechas",
          "Selecciona fecha de inicio",
          "Selecciona fecha de finalización",
          "Educación",
          "Secciones Personalizadas",
          "Antes de agregar una nueva sección primero debes de completar la última",
          "CV disponible en línea en:",
          "CV Desarrollado y Alojado por American Business Excellence Institute:",
          "Usar CV de Ejemplo",
          "CV Guardado",
          "Descargar",
          "Guardar",
        ],
      ),
    ],
  );

  TranslationTextListArray skill_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Skill",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Habilidad",
        ],
      ),
    ],
  );

  TranslationTextListArray employment_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Job Title",
          "at",
          "Company Name",
          "Job Location",
          "Responsabilities",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Puesto de Trabajo",
          "en",
          "Nombre de la Empresa",
          "Ubicación de Trabajo",
          "Responsabilidades",
        ],
      ),
    ],
  );

  TranslationTextListArray education_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Career Name",
          "Univesrity Name",
          "Univesrity Location",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Nombre de la Carrera",
          "Nombre de la Universidad",
          "Ubicación de la Universidad",
        ],
      ),
    ],
  );

  TranslationTextListArray picker_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Choose Profile Picture",
          "Choose Main Color",
          "Choose Color",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Selecciona la Imágen de Perfil",
          "Selecciona el Color Principal",
          "Selecciona el Color",
        ],
      ),
    ],
  );

  TranslationTextListArray sections_by_page_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Enter the numbers of sections by page separate by comas",
          "Example: 7, 2",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Ingresa los números de secciones por página separados por comas",
          "Ejemplo: 7, 2",
        ],
      ),
    ],
  );

  late TranslationStream translation_stream;
  late TranslationStream skill_translation_stream;
  late TranslationStream employment_translation_stream;
  late TranslationStream education_translation_stream;
  late TranslationStream picker_translation_stream;
  late TranslationStream sections_by_page_translation_stream;

  List<TranslationStream> translation_stream_list = [];

  int source_language_index = 1;

  update_source_language({
    required int new_source_language_index,
  }) {
    source_language_index = new_source_language_index;
    setState(() {});
    apply_timer();
  }

  update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    if (list_index == 0) {
      text_list.get(source_language_index)[index] = new_text;
    } else if (list_index == 1) {
      skill_text_list.get(source_language_index)[index] = new_text;
    } else if (list_index == 2) {
      employment_text_list.get(source_language_index)[index] = new_text;
    } else if (list_index == 3) {
      education_text_list.get(source_language_index)[index] = new_text;
    } else if (list_index == 4) {
      picker_text_list.get(source_language_index)[index] = new_text;
    } else if (list_index == 5) {
      sections_by_page_text_list.get(source_language_index)[index] = new_text;
    }

    setState(() {});
  }

  String chosen_image_src = "";
  String chosen_image_ext = "";

  List<ResumeSkill> skill_sections = [];
  List<ResumeSection> employment_sections = [];
  List<ResumeSection> education_sections = [];
  List<ResumeSection> custom_sections = [];

  update_item(int item_index, int section_index, dynamic section) {
    if (section_index == 0) {
      //
      if (item_index < skill_sections.length) {
        skill_sections[item_index] = section;
      } else {
        skill_sections.add(section);
      }
      //
    } else if (section_index == 1) {
      //
      if (item_index < employment_sections.length) {
        employment_sections[item_index] = section;
      } else {
        employment_sections.add(section);
      }
      //
    } else if (section_index == 2) {
      //
      if (item_index < education_sections.length) {
        education_sections[item_index] = section;
      } else {
        education_sections.add(section);
      }
      //
    } else if (section_index == 3) {
      //
      if (item_index < custom_sections.length) {
        custom_sections[item_index] = section;
      } else {
        custom_sections.add(section);
      }
      //
    }
    setState(() {});
  }

  remove_item(int item_index, int section_index) {
    if (section_index == 0) {
      skill_sections.removeAt(item_index);
    } else if (section_index == 1) {
      employment_sections.removeAt(item_index);
    } else if (section_index == 2) {
      education_sections.removeAt(item_index);
    } else if (section_index == 3) {
      custom_sections.removeAt(item_index);
    }
    setState(() {});
  }

  choose_profile_image() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      chosen_image_src = base64Encode(result.files.single.bytes!);
      chosen_image_ext = result.files.single.extension!;
      setState(() {});
    }
  }

  Color picker_color = Colors.blue;
  Color current_color = Colors.blue;

  choose_color() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            picker_text_list.get(source_language_index)[1],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picker_color,
              onColorChanged: (Color new_color) {
                picker_color = new_color;
                setState(() {});
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => current_color = picker_color);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  late User current_user;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    translation_stream = TranslationStream(
      translation_text_list_array: text_list,
      update_text_list_function: update_text_list,
      list_index: 0,
      source_language_index: source_language_index,
    );

    skill_translation_stream = TranslationStream(
      translation_text_list_array: skill_text_list,
      update_text_list_function: update_text_list,
      list_index: 1,
      source_language_index: source_language_index,
    );

    employment_translation_stream = TranslationStream(
      translation_text_list_array: employment_text_list,
      update_text_list_function: update_text_list,
      list_index: 2,
      source_language_index: source_language_index,
    );

    education_translation_stream = TranslationStream(
      translation_text_list_array: education_text_list,
      update_text_list_function: update_text_list,
      list_index: 3,
      source_language_index: source_language_index,
    );

    picker_translation_stream = TranslationStream(
      translation_text_list_array: picker_text_list,
      update_text_list_function: update_text_list,
      list_index: 4,
      source_language_index: source_language_index,
    );

    sections_by_page_translation_stream = TranslationStream(
      translation_text_list_array: sections_by_page_text_list,
      update_text_list_function: update_text_list,
      list_index: 5,
      source_language_index: source_language_index,
    );

    translation_stream_list = [
      translation_stream,
      skill_translation_stream,
      employment_translation_stream,
      education_translation_stream,
      picker_translation_stream,
      sections_by_page_translation_stream,
    ];
    apply_timer();
  }

  apply_timer() async {
    BrowserType browser_type = await check_browser_type();
    int timer_duration = browser_type == BrowserType.mobile ? 3000 : 1200;

    Timer(Duration(milliseconds: timer_duration), () {
      current_user = FirebaseAuth.instance.currentUser!;
      check_for_remote_resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    screen_height = MediaQuery.of(context).size.height;
    screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    Resume resume = generate_resume();

    return Scaffold(
      appBar: TopBar(
        context: context,
        background_color: widget.color_topbar,
        has_back_button: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: resume_editor_fab(resume),
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
                    height: sized_box_space * 4,
                  ),
                  SizedBox(
                    width: screen_width,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all<double>(
                          0,
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.transparent,
                        ),
                        overlayColor: MaterialStateProperty.all<Color>(
                          Colors.grey.withOpacity(0.2),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width,
                            ),
                            side: BorderSide(
                              color: widget.color_topbar,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {
                        check_for_remote_resume(load_example: true);
                      },
                      child: Text(
                        text_list.get(source_language_index)[20],
                        style: TextStyle(
                          color: widget.color_topbar,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: sized_box_space,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.only(right: 5),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all<double>(
                                0,
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.transparent,
                              ),
                              overlayColor: MaterialStateProperty.all<Color>(
                                Colors.grey.withOpacity(0.2),
                              ),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width,
                                  ),
                                  side: BorderSide(
                                    color: widget.color_topbar,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              choose_profile_image();
                            },
                            child: Text(
                              picker_text_list.get(source_language_index)[0],
                              style: TextStyle(
                                color: widget.color_topbar,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.only(left: 5),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all<double>(
                                0,
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                current_color,
                              ),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              choose_color();
                            },
                            child: Text(
                              picker_text_list.get(source_language_index)[1],
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[0],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
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
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[1],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
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
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[2],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
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
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[3],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
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
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: text_list.get(source_language_index)[5],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
                        ),
                      ),
                    ),
                    controller: profile_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.email,
                    ).validate(),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  ResumeSectionForm(
                    resume_section_form_type: ResumeSectionFormType.skill,
                    text_list: text_list.get(source_language_index).sublist(7, 18) +
                        skill_text_list.get(source_language_index) +
                        picker_text_list.get(source_language_index) +
                        text_list.get(source_language_index).sublist(4, 5),
                    text_color: widget.color_topbar,
                    language_code: text_list.list[source_language_index].source_language,
                    section_index: 0,
                    update_item: update_item,
                    remove_item: remove_item,
                    section_list: skill_sections,
                  ),
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sections_by_page_text_list.get(source_language_index)[0],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextFormField(
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: sections_by_page_text_list.get(source_language_index)[1],
                      labelStyle: TextStyle(
                        color: widget.color_topbar,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.color_topbar,
                        ),
                      ),
                    ),
                    controller: sections_by_page_input_controller,
                    validator: (value) => FormFieldValidators(
                      value: value!,
                      type: FormFieldValidatorsType.name,
                    ).validate(),
                  ),
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  ResumeSectionForm(
                    resume_section_form_type: ResumeSectionFormType.employment_history,
                    text_list: text_list.get(source_language_index).sublist(7, 18) +
                        employment_text_list.get(source_language_index),
                    text_color: widget.color_topbar,
                    language_code: text_list.list[source_language_index].source_language,
                    section_index: 1,
                    update_item: update_item,
                    remove_item: remove_item,
                    section_list: employment_sections,
                  ),
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  ResumeSectionForm(
                    resume_section_form_type: ResumeSectionFormType.education,
                    text_list: text_list.get(source_language_index).sublist(7, 18) +
                        education_text_list.get(source_language_index),
                    text_color: widget.color_topbar,
                    language_code: text_list.list[source_language_index].source_language,
                    section_index: 2,
                    update_item: update_item,
                    remove_item: remove_item,
                    section_list: education_sections,
                  ),
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  ResumeSectionForm(
                    resume_section_form_type: ResumeSectionFormType.custom,
                    text_list: text_list.get(source_language_index).sublist(7, 18),
                    text_color: widget.color_topbar,
                    language_code: text_list.list[source_language_index].source_language,
                    section_index: 3,
                    update_item: update_item,
                    remove_item: remove_item,
                    section_list: custom_sections,
                  ),
                  SizedBox(
                    height: sized_box_space * 4,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.all(portrait ? 6 : 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepOrangeAccent,
                  width: 6,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: double.maxFinite,
                    padding: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.deepOrangeAccent,
                          width: 6,
                        ),
                      ),
                    ),
                    child: Text(
                      text_list.get(source_language_index)[6],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ResumeVisualizer(
                    resume: resume,
                    language_code: text_list.list[source_language_index].source_language,
                    base_url: widget.base_url,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  show_saved_snack_bar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          text_list.get(source_language_index)[21],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
