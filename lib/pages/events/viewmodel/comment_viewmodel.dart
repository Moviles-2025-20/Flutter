import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lru_cache/lru_cache.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../util/firebase_service.dart';

class CommentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final LruCache<String, Map<String, dynamic>> _memoryCache =
      LruCache<String, Map<String, dynamic>>(50);
  final CacheManager _imageCache = DefaultCacheManager();

  CommentViewModel() {
    _listenNetworkChanges();
  }

  /// Escucha cambios de red y reintenta subidas pendientes
  void _listenNetworkChanges() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint("Conexión restablecida, intentando subir pendientes...");
        await _retryPendingUploads();
      }
    });
  }

  /// Enviar comentario (con caché, local storage, y fallback offline)
  Future<void> submitComment({
    required String eventId,
    required String title,
    required String description,
    required int rating,
    File? imageFile,
    required String userName,
    required String avatar,
  }) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await compute(_uploadImage, {
          'eventId': eventId,
          'path': imageFile.path,
        });

        // Cachear la imagen localmente (en disco)
        await _imageCache.putFile(
          imageUrl!,
          await imageFile.readAsBytes(),
          fileExtension: 'jpg',
        );
      }

      final commentData = {
        "eventId": eventId,
        "title": title,
        "description": description,
        "rating": rating,
        "imageUrl": imageUrl ?? '',
        "created": DateTime.now().toIso8601String(),
        "userName": userName,
        "avatar": avatar,
      };

      final cacheKey = "${eventId}_${DateTime.now().millisecondsSinceEpoch}";
      _memoryCache[cacheKey] = commentData;
      await _saveCommentLocally(commentData);

      // Verificar conexión antes de intentar subir
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint("Sin conexión — comentario guardado para subir luego");
        await _addPendingUpload(commentData);
        return;
      }

      //Intentar subida inmediata si hay conexión
      await _uploadToFirebase(eventId, commentData);
    } catch (e) {
      debugPrint("Error al enviar comentario: $e");
      await _addPendingUpload({
        ...commentDataForBackup(
          eventId: eventId,
          title: title,
          description: description,
          rating: rating,
          imageFile: imageFile,
          userName: userName,
          avatar: avatar,
        ),
      });
    }
  }

  ///  Subida de imagen
  static Future<String> _uploadImage(Map<String, dynamic> args) async {
    final String eventId = args['eventId'];
    final String path = args['path'];

    final file = File(path);
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref =
        FirebaseStorage.instance.ref().child("comments/$eventId/$fileName");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Subida a Firebase (si hay conexión)
  Future<void> _uploadToFirebase(
      String eventId, Map<String, dynamic> commentData) async {
    try {
      await _firestore.collection("comments").add(commentData);
      await _firestore.collection("events").doc(eventId).update({
        "stats.rating_list": FieldValue.arrayUnion([commentData["rating"]]),
      });
      debugPrint("Comentario sincronizado con Firestore");
    } catch (e) {
      debugPrint("Error al sincronizar comentario con Firebase: $e");
      await _addPendingUpload(commentData);
    }
  }

  /// Guardar comentario en archivo local (cache persistente)
  Future<void> _saveCommentLocally(Map<String, dynamic> comment) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/comments_cache.json');
    List<dynamic> existing = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      existing = json.decode(content);
    }

    existing.insert(0, comment);
    if (existing.length > 100) existing = existing.sublist(0, 100);

    await file.writeAsString(json.encode(existing));
  }

  /// Añadir comentario a la cola de subidas pendientes
  Future<void> _addPendingUpload(Map<String, dynamic> comment) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pending_uploads.json');
    List<dynamic> pending = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      pending = json.decode(content);
    }

    pending.add(comment);
    await file.writeAsString(json.encode(pending));
    debugPrint("Comentario agregado a subidas pendientes");
  }

  /// Reintentar subidas pendientes cuando vuelva la conexión
  Future<void> _retryPendingUploads() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pending_uploads.json');
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final List<dynamic> pending = json.decode(content);

    if (pending.isEmpty) return;

    debugPrint("Reintentando ${pending.length} subidas pendientes...");

    List<Map<String, dynamic>> remaining = [];

    for (var comment in pending) {
      try {
        await _uploadToFirebase(comment["eventId"], Map<String, dynamic>.from(comment));
      } catch (e) {
        remaining.add(Map<String, dynamic>.from(comment));
      }
    }

    await file.writeAsString(json.encode(remaining));
    debugPrint("Subidas pendientes procesadas, ${remaining.length} restantes");
  }

  /// Helper: reconstruye datos para respaldo en errores
  Map<String, dynamic> commentDataForBackup({
    required String eventId,
    required String title,
    required String description,
    required int rating,
    File? imageFile,
    required String userName,
    required String avatar,
  }) {
    return {
      "eventId": eventId,
      "title": title,
      "description": description,
      "rating": rating,
      "imageUrl": imageFile?.path ?? '',
      "created": DateTime.now().toIso8601String(),
      "userName": userName,
      "avatar": avatar,
    };
  }
}

extension on LruCache<String, Map<String, dynamic>> {
  void operator []=(String index, Map<String, Object> newValue) {}
}
