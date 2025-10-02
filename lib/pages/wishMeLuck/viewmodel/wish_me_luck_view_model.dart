
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/wish_me_luck_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class WishMeLuckViewModel extends ChangeNotifier {
  final WishMeLuckService _service = WishMeLuckService();

  WishMeLuckEvent? _currentEvent;
  bool _isLoading = false;
  String? _error;

  WishMeLuckEvent? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _error = null;
    } catch (e) {
      _error = 'Error al obtener evento: $e';
      _currentEvent = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEvent() {
    _currentEvent = null;
    _error = null;
    notifyListeners();
  }
}