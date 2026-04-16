import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> uploadImage(Uint8List bytes) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final ref = storage.ref().child('products/$fileName.jpg');

      await ref.putData(bytes);

      final url = await ref.getDownloadURL();

      print("🔥 IMAGE UPLOADED: $url");

      return url;
    } catch (e) {
      print("❌ STORAGE ERROR: $e");
      return "";
    }
  }
}
