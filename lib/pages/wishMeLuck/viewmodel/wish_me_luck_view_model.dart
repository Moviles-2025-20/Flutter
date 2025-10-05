
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/wish_me_luck_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class WishMeLuckViewModel extends ChangeNotifier {
  final WishMeLuckService _service = WishMeLuckService();

  WishMeLuckEvent? _currentEvent;
  Event? _currentEventDetail;
  bool _isLoading = false;
  String? _error;
  int _lastWishedTime = -1;

  WishMeLuckEvent? get currentEvent => _currentEvent;
  Event? get currentEventDetail => _currentEventDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get lastWished => _lastWishedTime;

  // Message
  String getMotivationalMessage() {
    if (_currentEvent == null) return '';

    final messages = [
      'The stars align for "${_currentEvent!.title}"! ✨',
      'Destiny says "${_currentEvent!.title}" is for you! 🍀',
      '"${_currentEvent!.title}" is waiting for you! 🌟',
      'Good luck with "${_currentEvent!.title}"! 💫',
    ];

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  Future<void> wishMeLuck() async {
    _isLoading = true;
    _error = null;
    _currentEvent = null;
    notifyListeners();

    try {
      // Simular shake/animation delay
      await Future.delayed(const Duration(milliseconds: 1500));


      _currentEvent = await _service.getWishMeLuckEvent();
      _currentEventDetail = await _service.getWishMeLuckEventDetail(_currentEvent!.id);
      await _service.setLastWishedDate(DateTime.now());
      await calculateDaysSinceLastWished();
      
      
      _error = null;
    } catch (e) {
      _error = 'Error al obtener evento: $e';
      _currentEvent = null;
    } finally {
      calculateDaysSinceLastWished();
      await _service.setLastWishedDate(DateTime.now());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateDaysSinceLastWished() async {
    final now = DateTime.now();
    final DateTime? lastWishedDate = await _service.getLastWishedDate();


    if (lastWishedDate == null) {
      // Nunca se ha deseado suerte antes
      await _service.setLastWishedDate(now);
      _lastWishedTime = 0;
    } else {
      final difference = now.difference(lastWishedDate).inDays;
      _lastWishedTime = difference;
      notifyListeners(); 
    }

  }

  void clearEvent() {
    _currentEvent = null;
    _error = null;
    notifyListeners();
  }
}