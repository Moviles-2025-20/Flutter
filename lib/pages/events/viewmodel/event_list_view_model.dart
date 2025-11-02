import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/event_cache_service.dart';
import 'package:app_flutter/util/event_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsViewModel extends ChangeNotifier {
  bool _isMapView;
  final EventsService _service = EventsService();
  final EventsCacheService _cacheService = EventsCacheService();
  final AnalyticsService _analytics = AnalyticsService();
  final user = FirebaseAuth.instance.currentUser;

  List<Event> _events = [];
  bool _isLoading = false;
  bool _isLoadingMore = false; // Loading more in background
  String? _error;
  EventFilters _filters = EventFilters();
  List<String> _availableCities = [];
  List<String> _availableCategories = [];

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isMapView => _isMapView;
  EventFilters get filters => _filters;
  List<String> get availableCities => _availableCities;
  List<String> get availableCategories => _availableCategories;

  EventsViewModel({bool initialIsMapView = false}) 
      : _isMapView = initialIsMapView {
    loadEvents();
    loadFilterOptions();
  }

  void toggleView() {
    _isMapView = !_isMapView;
    if (_isMapView){
      _analytics.logMapUsed(user!.uid);
    }
    notifyListeners();
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }


  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedEvents = await _cacheService.getEvents(_filters);

      if (cachedEvents.isNotEmpty) {
        // Show cached immediately
        const int immediateCount = 5;
        _events = cachedEvents.take(immediateCount).toList();
        _isLoading = false;
        notifyListeners();
        debugPrint('Showing ${_events.length} of ${cachedEvents.length} cached events');

        // Refresh in background if online
        if (await _hasInternet()) {
          _refreshEventsInBackground();
        } else {
          _queueRefreshForLater();
        }

        return;
      }

      // No cache and offline
      if (!await _hasInternet()) {
        _error = 'No events, check yor internet connection';
        _events = [];
        _isLoading = false;
        notifyListeners();
        debugPrint('No cache and offline');
        return;
      }

      // No cache but online → fetch fresh
      final fresh = await _service.getEvents(filters: _filters);
      _events = fresh;
      await _cacheService.saveEvents(fresh, _filters);
      _isLoading = false;
      notifyListeners();
      debugPrint('Loaded ${_events.length} events from network (cache miss)');
    } catch (e) {
      _error = 'Error loading events: $e';
      _events = [];
      _isLoading = false;
      notifyListeners();
      debugPrint('Exception: $e');
    }
  }

  final List<EventFilters> _pendingRefreshes = [];

  void _queueRefreshForLater() {
    _pendingRefreshes.add(_filters);
    debugPrint('Queued refresh for later: ${_filters.toString()}');
  }



  void _refreshEventsInBackground() {
  () async {
    if (_isDisposed) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final fresh = await _service.getEvents(filters: _filters);
      if (fresh.isNotEmpty) {
        _events = fresh;
        await _cacheService.saveEvents(fresh, _filters);
        debugPrint('Refreshed ${fresh.length} events in background');
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }();
}


  Future<void> loadFilterOptions() async {
    try {
      _availableCities = await _service.getAvailableCities();
      _availableCategories = await _service.getAvailableCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filter options: $e');
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

  /// Force refresh - clear cache and reload
  Future<void> forceRefresh() async {
    await _cacheService.clearAllCache();
    await loadEvents();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}