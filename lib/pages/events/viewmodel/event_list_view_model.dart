import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:app_flutter/widgets/event_service.dart';
import 'package:flutter/material.dart';

class EventsViewModel extends ChangeNotifier {
  final EventsService _service = EventsService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;
  bool _isMapView = false;
  EventFilters _filters = EventFilters();
  List<String> _availableCities = [];
  List<String> _availableCategories = [];

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMapView => _isMapView;
  EventFilters get filters => _filters;
  List<String> get availableCities => _availableCities;
  List<String> get availableCategories => _availableCategories;

  EventsViewModel() {
    loadEvents();
    loadFilterOptions();
  }

  void toggleView() {
    _isMapView = !_isMapView;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _service.getEvents(filters: _filters);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFilterOptions() async {
    try {
      _availableCities = await _service.getAvailableCities();
      _availableCategories = await _service.getAvailableCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading filter options: $e');
    }
  }

  void updateSearchQuery(String query) {
    _filters = _filters.copyWith(searchQuery: query);
    loadEvents();
  }

  void updateEventTypes(List<String> types) {
    _filters = _filters.copyWith(eventTypes: types);
    loadEvents();
  }

  void updateCategory(String? category) {
    _filters = _filters.copyWith(category: category);
    loadEvents();
  }

  void updateMinRating(double? rating) {
    _filters = _filters.copyWith(minRating: rating);
    loadEvents();
  }

  void updateCity(String? city) {
    _filters = _filters.copyWith(city: city);
    loadEvents();
  }

  void clearFilters() {
    _filters = EventFilters();
    loadEvents();
  }
}
