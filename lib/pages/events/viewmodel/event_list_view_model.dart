import 'dart:async';
import 'dart:io';
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
  bool _isLoadingMore = false;
  String? _error;
  EventFilters _filters = EventFilters();
  List<String> _availableCities = [];
  List<String> _availableCategories = [];
  
  // Connectivity
  bool _hasInternet = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final List<EventFilters> _pendingRefreshes = [];

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isMapView => _isMapView;
  EventFilters get filters => _filters;
  List<String> get availableCities => _availableCities;
  List<String> get availableCategories => _availableCategories;
  bool get hasInternet => _hasInternet;

  EventsViewModel({bool initialIsMapView = false}) 
      : _isMapView = initialIsMapView {
    _startConnectivityListener();
    loadEvents();
    loadFilterOptions();
  }

  // ============== CONNECTIVITY LISTENER ==============

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        await _onConnectivityChanged(result);
      },
    );
    
    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        _hasInternet = false;
      } else {
        _hasInternet = await _verifyInternetConnection();
      }
      debugPrint('Estado inicial de internet (Events): $_hasInternet');
    } catch (e) {
      debugPrint('Error al verificar conectividad inicial: $e');
      _hasInternet = false;
    }
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    try {
      debugPrint('Connectivity changed (Events): $result');
      
      final wasOffline = !_hasInternet;
      
      if (result == ConnectivityResult.none) {
        // Lost connection
        debugPrint('Internet connection lost (Events)');
        _hasInternet = false;
        notifyListeners();
      } else {
        // Potentially gained connection - verify real connectivity
        debugPrint('Connection detected (Events), verifying...');
        final realConnection = await _verifyInternetConnection();
        
        if (realConnection && !_hasInternet) {
          // Internet recovered
          debugPrint('Internet connection recovered (Events)!');
          _hasInternet = true;
          notifyListeners();
          
          // If was offline, process pending refreshes
          if (wasOffline) {
            debugPrint('Processing pending refreshes (Events)...');
            await _processPendingRefreshes();
          }
        } else if (!realConnection) {
          // False positive - still no real internet
          debugPrint('Connected but no real internet (Events)');
          _hasInternet = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error en _onConnectivityChanged: $e');
    }
  }

  Future<bool> _verifyInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Error verifying internet: $e');
      return false;
    }
  }

  Future<void> _processPendingRefreshes() async {
    if (_pendingRefreshes.isEmpty) {
      debugPrint('No pending refreshes to process');
      return;
    }
    
    debugPrint('Processing ${_pendingRefreshes.length} pending refresh(es)');
    
    // Process the most recent filter (usually the current one)
    final filtersToRefresh = _pendingRefreshes.last;
    _pendingRefreshes.clear();
    
    // Refresh with the pending filters
    final previousFilters = _filters;
    _filters = filtersToRefresh;
    
    await _refreshEventsInBackground();
    
    // Restore original filters if they changed
    if (previousFilters != filtersToRefresh) {
      _filters = previousFilters;
    }
  }

  // ============== EVENTS LOADING ==============

  void toggleView() {
    _isMapView = !_isMapView;
    if (_isMapView){
      _analytics.logMapUsed(user!.uid);
    }
    notifyListeners();
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
        if (_hasInternet) {
          _refreshEventsInBackground();
        } else {
          _queueRefreshForLater();
        }

        return;
      }

      // No cache and offline
      if (!_hasInternet) {
        _error = 'No events, check your internet connection';
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

  void _queueRefreshForLater() {
    _pendingRefreshes.add(_filters);
    debugPrint('Queued refresh for later: ${_filters.toString()}');
  }

  Future<void> _refreshEventsInBackground() async {
    if (_isDisposed) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final fresh = await _service.getEvents(filters: _filters).timeout(
        const Duration(seconds: 10),
      );
      
      if (fresh.isNotEmpty && !_isDisposed) {
        _events = fresh;
        await _cacheService.saveEvents(fresh, _filters);
        debugPrint('✅ Refreshed ${fresh.length} events in background');
      }
    } catch (e) {
      debugPrint('❌ Background refresh failed: $e');
      // Update internet status if it was a network error
      if (e is SocketException || e is TimeoutException) {
        _hasInternet = false;
        _queueRefreshForLater();
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
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
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}