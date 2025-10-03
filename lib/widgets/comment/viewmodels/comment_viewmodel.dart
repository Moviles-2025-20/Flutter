import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class CommentViewModel extends ChangeNotifier {
  Future<void> submitComment({
    required String eventId,
    required String title,
    required String description,
    required int rating,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('events/$eventId/comments/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .add({
        'title': title,
        'description': description,
        'rating': rating,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error al enviar comentario: $e");
    }
  }
}
