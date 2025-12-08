import 'package:cloud_firestore/cloud_firestore.dart';

class EventChoice {
  final String name;
  final String color;

  EventChoice({
    required this.name,
    required this.color,
  });

  factory EventChoice.fromMap(Map<String, dynamic> data) {
    final choice_key = data.keys.first;
    final choice_value = data[choice_key] as Map<String, dynamic>? ?? {};
    return EventChoice(
      name: choice_key,
      color: choice_value['color'] ?? 'FFFFFF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      name: {'color': color},
    };
  }
}

class EventModel {
  final String id;
  final String baby_name;
  final String background_color;
  final List<EventChoice> choices;
  final Timestamp created_at;
  final String created_by;
  final String main_color;
  final List<String> organizers_names;
  final Timestamp reveal_date;
  final String secondary_color;
  final String subtitle;
  final String title;
  final Timestamp? baby_delivery_date;

  EventModel({
    required this.id,
    required this.baby_name,
    required this.background_color,
    required this.choices,
    required this.created_at,
    required this.created_by,
    required this.main_color,
    required this.organizers_names,
    required this.reveal_date,
    required this.secondary_color,
    required this.subtitle,
    required this.title,
    this.baby_delivery_date,
  });

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      baby_name: data['baby_name'] ?? '',
      background_color: data['background_color'] ?? 'FFFFFF',
      choices: (data['choices'] as List<dynamic>? ?? [])
          .map((element) => EventChoice.fromMap(Map<String, dynamic>.from(element)))
          .toList(),
      created_at: data['created_at'] ?? Timestamp.now(),
      created_by: data['created_by'] ?? '',
      main_color: data['main_color'] ?? 'FFFFFF',
      organizers_names: (data['organizers_names'] as List<dynamic>? ?? []).cast<String>(),
      reveal_date: data['reveal_date'] ?? Timestamp.now(),
      secondary_color: data['secondary_color'] ?? 'FFFFFF',
      subtitle: data['subtitle'] ?? '',
      title: data['title'] ?? '',
      baby_delivery_date: data['baby_delivery_date'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baby_name': baby_name,
      'background_color': background_color,
      'choices': choices.map((choice) => choice.toMap()).toList(),
      'created_at': created_at,
      'created_by': created_by,
      'main_color': main_color,
      'organizers_names': organizers_names,
      'reveal_date': reveal_date,
      'secondary_color': secondary_color,
      'subtitle': subtitle,
      'title': title,
      if (baby_delivery_date != null) 'baby_delivery_date': baby_delivery_date,
    };
  }
}
