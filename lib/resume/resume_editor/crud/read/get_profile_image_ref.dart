import 'package:firebase_storage/firebase_storage.dart';

Reference get_profile_image_ref({
  required String chosen_image_path,
}) {
  return FirebaseStorage.instance.ref().child(chosen_image_path);
}
