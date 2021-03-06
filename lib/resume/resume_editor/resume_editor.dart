import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_visualizer/resume_visualizer.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:xapptor_ui/widgets/topbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ResumeEditor extends StatefulWidget {
  const ResumeEditor({
    required this.color_topbar,
    required this.base_url,
  });

  final Color color_topbar;
  final String base_url;

  @override
  _ResumeEditorState createState() => _ResumeEditorState();
}

class _ResumeEditorState extends State<ResumeEditor> {
  TextEditingController name_input_controller = TextEditingController();
  TextEditingController job_title_input_controller = TextEditingController();
  TextEditingController email_input_controller = TextEditingController();
  TextEditingController website_input_controller = TextEditingController();
  TextEditingController profile_input_controller = TextEditingController();
  TextEditingController sections_by_page_input_controller =
      TextEditingController();

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
          "Resume Saved",
          "Save",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Nombre Completo",
          "Puesto de Trabajo",
          "Correo Electr??nico",
          "P??gina Web",
          "Puntos de Destreza",
          "Perfil",
          "Vista Previa del CV",
          "Historial de Empleo",
          "T??tulo",
          "Subt??tulo",
          "Descripci??n",
          "Presente",
          "Seleccionar Fechas",
          "Selecciona fecha de inicio",
          "Selecciona fecha de finalizaci??n",
          "Educaci??n",
          "Secciones Personalizadas",
          "Antes de agregar una nueva secci??n primero debes de completar la ??ltima",
          "CV disponible en l??nea en:",
          "CV Guardado",
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
          "Ubicaci??n de Trabajo",
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
          "Ubicaci??n de la Universidad",
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
          "Selecciona la Im??gen de Perfil",
          "Selecciona el Color Principal",
          "Selecciona el Color",
        ],
      ),
    ],
  );

  TranslationTextListArray sections_by_page_text_list =
      TranslationTextListArray(
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
          "Ingresa los n??meros de secciones por p??gina separados por comas",
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

    Timer(Duration(milliseconds: 600), () {
      current_user = FirebaseAuth.instance.currentUser!;
      check_for_remote_resume();
    });
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
            margin: EdgeInsets.only(right: 20),
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
                    height: sized_box_space * 4,
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
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
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
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
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
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
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
                    onChanged: (new_value) {
                      setState(() {});
                    },
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
                    onChanged: (new_value) {
                      setState(() {});
                    },
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
                    onChanged: (new_value) {
                      setState(() {});
                    },
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
                    onChanged: (new_value) {
                      setState(() {});
                    },
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
                    text_list:
                        text_list.get(source_language_index).sublist(7, 18) +
                            skill_text_list.get(source_language_index) +
                            picker_text_list.get(source_language_index) +
                            text_list.get(source_language_index).sublist(4, 5),
                    text_color: widget.color_topbar,
                    language_code:
                        text_list.list[source_language_index].source_language,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextFormField(
                    onChanged: (new_value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: widget.color_topbar,
                    ),
                    decoration: InputDecoration(
                      labelText: sections_by_page_text_list
                          .get(source_language_index)[1],
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
                    resume_section_form_type:
                        ResumeSectionFormType.employment_history,
                    text_list:
                        text_list.get(source_language_index).sublist(7, 18) +
                            employment_text_list.get(source_language_index),
                    text_color: widget.color_topbar,
                    language_code:
                        text_list.list[source_language_index].source_language,
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
                    text_list:
                        text_list.get(source_language_index).sublist(7, 18) +
                            education_text_list.get(source_language_index),
                    text_color: widget.color_topbar,
                    language_code:
                        text_list.list[source_language_index].source_language,
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
                    text_list:
                        text_list.get(source_language_index).sublist(7, 18),
                    text_color: widget.color_topbar,
                    language_code:
                        text_list.list[source_language_index].source_language,
                    section_index: 3,
                    update_item: update_item,
                    remove_item: remove_item,
                    section_list: custom_sections,
                  ),
                  SizedBox(
                    height: sized_box_space * 2,
                  ),
                  Container(
                    width: screen_width,
                    child: FractionallySizedBox(
                      widthFactor: 0.3,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.all<double>(
                            0,
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            widget.color_topbar,
                          ),
                          overlayColor: MaterialStateProperty.all<Color>(
                            Colors.grey.withOpacity(0.2),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width,
                              ),
                            ),
                          ),
                        ),
                        onPressed: () {
                          save_resume();
                        },
                        child: Text(
                          text_list.get(source_language_index).last,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.deepOrangeAccent,
                          width: 6,
                        ),
                      ),
                    ),
                    child: Text(
                      text_list.get(source_language_index)[6],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ResumeVisualizer(
                    resume: generate_resume(),
                    language_code:
                        text_list.list[source_language_index].source_language,
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

  save_resume() async {
    if (chosen_image_src.isNotEmpty) {
      if (!chosen_image_src.contains("http")) {
        Reference profile_image_ref = await FirebaseStorage.instance
            .ref()
            .child('users')
            .child('/' + current_user.uid)
            .child('/resumes')
            .child('/profile_image.' + chosen_image_ext);

        await profile_image_ref
            .putData(base64Decode(chosen_image_src))
            .then((p0) async {
          chosen_image_src = await p0.ref.getDownloadURL();
          set_resume();
        });
      } else {
        set_resume();
      }
    } else {
      set_resume();
    }
  }

  set_resume() async {
    String resume_doc_id = current_user.uid +
        "_" +
        text_list.list[source_language_index].source_language;

    DocumentReference resume_doc =
        FirebaseFirestore.instance.collection("resumes").doc(resume_doc_id);

    await resume_doc
        .set(
      generate_resume().to_json(),
      SetOptions(merge: true),
    )
        .then((value) {
      show_saved_snack_bar();
    });
  }

  show_saved_snack_bar() {
    int saved_text_index = text_list.get(source_language_index).length - 2;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          text_list.get(source_language_index)[saved_text_index],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  check_for_remote_resume() async {
    String resume_doc_id = current_user.uid +
        "_" +
        text_list.list[source_language_index].source_language;

    DocumentSnapshot resume_doc = await FirebaseFirestore.instance
        .collection("resumes")
        .doc(resume_doc_id)
        .get();

    Map? resume_map = resume_doc.data() as Map?;

    if (resume_map != null) {
      var remote_resume = Resume.from_snapshot(resume_doc_id, resume_map);

      chosen_image_src = remote_resume.image_src;
      current_color = remote_resume.icon_color;

      name_input_controller.text = remote_resume.name;
      job_title_input_controller.text = remote_resume.job_title;
      email_input_controller.text = remote_resume.email;
      website_input_controller.text = remote_resume.website;
      profile_input_controller.text =
          remote_resume.profile_section.description!;

      sections_by_page_input_controller.text =
          remote_resume.sections_by_page.join(", ");

      skill_sections = remote_resume.skills;
      employment_sections = remote_resume.employment_sections;
      education_sections = remote_resume.education_sections;
      custom_sections = remote_resume.custom_sections;

      setState(() {});
    } else {
      skill_sections = [
        ResumeSkill(
          name: "",
          percentage: 0.2,
          color: Colors.blue,
        ),
      ];
      employment_sections = [
        ResumeSection(),
      ];
      education_sections = [
        ResumeSection(),
      ];
    }
  }

  Resume generate_resume() {
    return Resume(
      image_src: chosen_image_src,
      name: name_input_controller.text,
      job_title: job_title_input_controller.text,
      email: email_input_controller.text,
      website: website_input_controller.text,
      skills_title: text_list.get(source_language_index)[4],
      skills: skill_sections,
      sections_by_page: sections_by_page_input_controller.text
          .replaceAll(" ", "")
          .split(",")
          .map((e) => int.tryParse(e) ?? 1)
          .toList(),
      profile_section: ResumeSection(
        icon: Icons.badge,
        code_point: 0xea67,
        title: text_list.get(source_language_index)[5],
        description: profile_input_controller.text,
      ),
      employment_sections: employment_sections,
      education_sections: education_sections,
      custom_sections: custom_sections,
      icon_color: current_color,
      language_code: text_list.list[source_language_index].source_language,
      text_list: [
        text_list.get(source_language_index)[11],
        text_list.get(source_language_index)[18],
      ],
    );
  }
}
