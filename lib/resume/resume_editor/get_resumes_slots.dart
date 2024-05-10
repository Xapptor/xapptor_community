import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_community/resume/models/resume.dart';

Future<List<Resume>> get_resumes_slots({
  required String resume_doc_id,
  required String user_id,
}) async {
  QuerySnapshot<Map<String, dynamic>> backups_snaps =
      await FirebaseFirestore.instance.collection("resumes").where("user_id", isEqualTo: user_id).get();

  List<Resume> backup_resumes = backups_snaps.docs.map((doc) => Resume.from_snapshot(doc.id, doc.data())).toList();

  backup_resumes = backup_resumes..sort((Resume a, Resume b) => a.slot_index.compareTo(b.slot_index));
  return backup_resumes;
}
