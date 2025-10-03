import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../util/firebase_service.dart';

class CommentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
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
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance.ref().child("comments/$eventId/$fileName");
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final commentData = {
        "eventId": eventId,
        "title": title,
        "description": description,
        "rating": rating,
        "imageUrl": imageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection("events")
          .doc(eventId)
          .collection("comments")
          .add(commentData);
      debugPrint("Guardando comentario en evento: ${eventId}");
      debugPrint(" Comentario guardado en Firestore");
    } catch (e) {
      debugPrint("Error al enviar comentario: $e");
    }
  }
}
