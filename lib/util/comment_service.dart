import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_flutter/pages/events/model/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Comment>> getCommentsForEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _firestore
          .collection('comments')
          .where('event_id', isEqualTo: eventId)
          .orderBy('created', descending: true)
          .limit(100);

      final QuerySnapshot snapshot = await query.get();

      List<Comment> comments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Comment.fromJson(doc.id, data);
      }).toList();

      return comments;
    } catch (e) {
      print('Error al obtener comentarios: $e');
      throw Exception('Error al obtener comentarios: $e');
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _firestore.collection('comments').add({
        'user_id': comment.user_id,
        'event_id': comment.event_id,
        'metadata': {
          'image_url': comment.metadata.imageUrl,
          'text': comment.metadata.text,
        },
        'created': Timestamp.fromDate(comment.created),
      });
    } catch (e) {
      print('Error al agregar comentario: $e');
      throw Exception('Error al agregar comentario: $e');
    }
  }

} 