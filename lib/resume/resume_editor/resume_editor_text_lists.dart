import 'package:xapptor_translation/model/text_list.dart';

class ResumeEditorTextLists {
  TranslationTextListArray text_list({
    required String organization_name,
  }) =>
      TranslationTextListArray(
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
              "Resume Developed and Hosted by $organization_name:",
              "Use Example Resume",
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
              "CV Desarrollado y Alojado por $organization_name:",
              "Usar CV de Ejemplo",
            ],
          ),
        ],
      );

  TranslationTextListArray alert_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Which slot do you want to load?",
          "Which slot do you want to delete?",
          "Are you sure you want to delete this Resume?",
          "In which slot do you want to save your Resume?",
          "Your Resume has been saved, do you want to save an extra backup?",
          "No",
          "Yes",
          "Cancel",
          "Backup",
          "Main",
          "You don't have backups at the moment",
          "First you must save one",
          "Ok",
          "Current Resume Slot",
          "Resume Loaded",
          "Resume Saved",
          "Resume Deleted",
          "Load",
          "Save",
          "Delete",
          "Download",
          "Menu",
          "Close",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "¿Qué ranura deseas cargar?",
          "¿Qué ranura deseas eliminar?",
          "¿Estás seguro de que deseas eliminar este CV?",
          "¿En qué ranura deseas guardar tu CV?",
          "Tu CV ha sido guardado, ¿deseas guardar un respaldo extra?",
          "No",
          "Sí",
          "Cancelar",
          "Respaldo",
          "Principal",
          "Por el momento no posees respaldos",
          "Primero debes guardar uno",
          "Ok",
          "Ranura Actual del CV",
          "CV Cargado",
          "CV Guardado",
          "CV Eliminado",
          "Cargar",
          "Guardar",
          "Eliminar",
          "Descargar",
          "Menú",
          "Cerrar",
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
          "Choose Photo",
          "Choose Main Color",
          "Choose Color",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Seleccionar Foto",
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

  TranslationTextListArray time_text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Year",
          "Years",
          "Month",
          "Months",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Año",
          "Años",
          "Mes",
          "Meses",
        ],
      ),
    ],
  );
}
