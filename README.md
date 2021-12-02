# **Xapptor Community**
[![pub package](https://img.shields.io/pub/v/xapptor_community?color=blue)](https://pub.dartlang.org/packages/xapptor_community)
### Module to create user communities.

## **Let's get started**

### **1 - Depend on it**
##### Add it to your package's pubspec.yaml file
```yml
dependencies:
    xapptor_community: ^0.0.1
```

### **2 - Install it**
##### Install packages from the command line
```sh
flutter pub get
```

### **3 - Learn it like a charm**

#### **Resume**
```dart
Resume(
    resume: Resume(
        image_src: "assets/images/resume_photo.png",
        name: "Javier Jesus Garcia Contreras",
        job_title: "Software Developer",
        email: "info@xapptor.com",
        url: "https://xapptor.com",
        skills: [
            ResumeSkill(
            name: "Experience: 5 years",
            percentage: 0.5,
            color: color_turquoise,
            ),
            ResumeSkill(
            name: "Communication",
            percentage: 0.8,
            color: color_purple,
            ),
            ResumeSkill(
            name: "Cognitive Flexibility",
            percentage: 0.8,
            color: color_magenta,
            ),
            ResumeSkill(
            name: "Negotiation",
            percentage: 0.7,
            color: Colors.amberAccent,
            ),
            ResumeSkill(
            name: "Health",
            percentage: 0.9,
            color: Colors.red,
            ),
            ResumeSkill(
            name: "Mana",
            percentage: 0.8,
            color: Colors.blueAccent,
            ),
        ],
        sections: [
            ResumeSection(
            icon: Icons.badge,
            code_point: 0xea67,
            title: "Profile",
            description:
                "I am a software developer passionate about Apps and artificial intelligence, I have participated in 3 projects implementing cognitive services of Microsoft Azure. I love working with Flutter and Firebase for the analysis, design and implementation of libraries to speed up the development of multi platform applications.",
            ),
            ResumeSection(
            icon: Icons.dvr_rounded,
            code_point: 0xe1b2,
            title: "Employment History",
            subtitle: "Software Developer at Keydok, Mexico City",
            begin: DateTime(2019, 10),
            end: DateTime.now(),
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
        icon_color: color_turquoise,
    ),
    visible: true,
);
```

### **4 - Check Abeinstitute Repo for more examples**
[Abeinstitute Repo](https://github.com/Xapptor/xapptor)

[Abeinstitute](https://xapptor.com/author)