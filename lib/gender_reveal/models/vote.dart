import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  final String id;
  final String choice;
  final String event_id;
  final String user_id;

  Vote({
    required this.id,
    required this.choice,
    required this.event_id,
    required this.user_id,
  });

  factory Vote.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Vote(
      id: doc.id,
      choice: data['choice'] ?? '',
      event_id: data['event_id'] ?? '',
      user_id: data['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choice': choice,
      'event_id': event_id,
      'user_id': user_id,
    };
  }
}
