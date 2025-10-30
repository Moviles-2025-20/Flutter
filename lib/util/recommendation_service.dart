import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:quiver/collection.dart';
import 'dart:io';


class RecommendationsController {
  final RecommendationService _service = RecommendationService();
  final RecommendationsStorageService _storage = RecommendationsStorageService();
  
  // Connectivity listener
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hasInternet = true;
  
  // Callbacks
  void Function(Map<String, dynamic> freshData)? _onRecommendationsUpdated;
  void Function(bool hasConnection)? _onConnectivityChanged;
  
  // Pending refresh queue
  final Set<String> _pendingRefreshes = {};

  RecommendationsController() {
    _startConnectivityListener();
  }

  // ============== CONNECTIVITY LISTENER ==============

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      debugPrint('Connectivity changed: $result');
      
      final wasOffline = !_hasInternet;
      
      if (result == ConnectivityResult.none) {
        // Lost connection
        debugPrint('Internet connection lost');
        _hasInternet = false;
        _onConnectivityChanged?.call(false);
      } else {
        // Potentially gained connection - verify real connectivity
        debugPrint('Connection detected, verifying...');
        final realConnection = await _verifyInternetConnection();
        
        if (realConnection && !_hasInternet) {
          // Internet recovered
          debugPrint('Internet connection recovered!');
          _hasInternet = true;
          _onConnectivityChanged?.call(true);
          
          // If was offline, process pending refreshes
          if (wasOffline) {
            _processPendingRefreshes();
          }
        } else if (!realConnection) {
          // False positive - still no real internet
          debugPrint('Connected but no real internet');
          _hasInternet = false;
          _onConnectivityChanged?.call(false);
        }
      }
    });
    
    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      _hasInternet = false;
      _onConnectivityChanged?.call(false);
    } else {
      _hasInternet = await _verifyInternetConnection();
      _onConnectivityChanged?.call(_hasInternet);
    }
  }

  Future<bool> _verifyInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Error verifying internet: $e');
      return false;
    }
  }

  void _processPendingRefreshes() {
    if (_pendingRefreshes.isEmpty) return;
    
    debugPrint('Processing ${_pendingRefreshes.length} pending refreshes');
    
    final userIds = List<String>.from(_pendingRefreshes);
    _pendingRefreshes.clear();
    
    for (final userId in userIds) {
      _refreshRecommendationsInBackground(userId);
    }
  }

  // ============== PUBLIC API ==============

  Future<Map<String, dynamic>?> getRecommendations(String userId) async {
    // Try cache/storage first
    final cached = await _storage.getRecommendations(userId);
    if (cached != null) {
      // Return cached and refresh in background if online
      if (_hasInternet) {
        _refreshRecommendationsInBackground(userId);
      } else {
        // Queue for later when internet returns
        _pendingRefreshes.add(userId);
        debugPrint('Queued refresh for when internet returns: $userId');
      }
      return cached;
    }

    // No cache - need to fetch
    if (!_hasInternet) {
      debugPrint('No cached data and no internet connection');
      return null;
    }

    try {
      final fresh = await _service.getRecommendations(userId);
      await _storage.storeRecommendations(userId, fresh);
      return fresh;
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      return null;
    }
  }

  void _refreshRecommendationsInBackground(String userId) async {
    if (!_hasInternet) {
      _pendingRefreshes.add(userId);
      debugPrint('No internet, queued for later: $userId');
      return;
    }

    debugPrint('Starting background refresh for: $userId');
    
    // Use isolate for heavy computation
    compute(_backgroundFetchAndStore, userId)
        .then((freshData) async {
          if (freshData != null) {
            debugPrint('Background refresh completed');
            await _storage.storeRecommendations(userId, freshData);
            _onRecommendationsUpdated?.call(freshData);
          } else {
            debugPrint('Background fetch returned null data');
          }
        })
        .catchError((e) {
          debugPrint('Background refresh failed: $e');
          // Queue for retry if it was a network error
          if (!_hasInternet) {
            _pendingRefreshes.add(userId);
          }
        });
  }

  /// Set callback
  void setOnRecommendationsUpdated(void Function(Map<String, dynamic>) callback) {
    _onRecommendationsUpdated = callback;
  }
  void setOnConnectivityChanged(void Function(bool hasConnection) callback) {
    _onConnectivityChanged = callback;
  }

  /// Getters
  bool get hasInternet => _hasInternet;
  int get pendingRefreshesCount => _pendingRefreshes.length;

  /// Force refresh for a user (if online)
  Future<void> forceRefresh(String userId) async {
    if (!_hasInternet) {
      debugPrint('Cannot force refresh - no internet');
      _pendingRefreshes.add(userId);
      return;
    }

    try {
      final fresh = await _service.getRecommendations(userId);
      await _storage.storeRecommendations(userId, fresh);
      _onRecommendationsUpdated?.call(fresh);
      debugPrint('Force refresh completed for: $userId');
    } catch (e) {
      debugPrint('Force refresh failed: $e');
    }
  }

  /// Dispose - clean up listener
  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingRefreshes.clear();
    debugPrint('RecommendationsController disposed');
  }
}

Future<Map<String, dynamic>?> _backgroundFetchAndStore(String userId) async {
  final service = RecommendationService();
  return await service.getRecommendations(userId);
}


//Fetch from back service

class RecommendationService {
  final String baseUrl = "https://us-central1-parchandes-7e096.cloudfunctions.net";

  Future<Map<String, dynamic>> getRecommendations(String userId) async {
    final url = Uri.parse("$baseUrl/get_recommendations?user_id=$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error getting recommendations: ${response.statusCode}");
    }
  }
}


/// Service that handles both temporary cache (LRU) and persistent storage (JSON)
class RecommendationsStorageService {
  static final RecommendationsStorageService _instance = RecommendationsStorageService._internal();
  factory RecommendationsStorageService() => _instance;
  RecommendationsStorageService._internal() {
    _initCache();
  }

  // ============== CACHE ==============
  late LruMap<String, Map<String, dynamic>> _cache;
  final int _maxCacheSize = 10;
  
  // ============== LOCAL STORAGE ==============
  static const String _storageFileName = 'recommendations_storage.json';

  void _initCache() {
    _cache = LruMap(maximumSize: _maxCacheSize);
    debugPrint('LRU Cache initialized (max: $_maxCacheSize)');
  }

  /// Get recommendations - checks cache first, then local storage
  Future<Map<String, dynamic>?> getRecommendations(String userId) async {
    // 1. Check memory cache first (fastest)
    final cached = _cache[userId];
    if (cached != null) {
      debugPrint('Cache HIT: $userId');
      return cached;
    }

    // 2. Check persistent local storage
    final stored = await getFromLocalStorage(userId);
    if (stored != null) {
      debugPrint('LocalStorage HIT: $userId');
      // Put in cache for faster access next time
      _cache[userId] = stored;
      return stored;
    }

    debugPrint('Not found in cache or storage: $userId');
    return null;
  }

  /// Store recommendations in BOTH cache and persistent storage
  Future<void> storeRecommendations(String userId, Map<String, dynamic> data) async {
    debugPrint('Storing recommendations for: $userId');
    
    // Store in memory cache (temporary)
    _cache[userId] = data;
    
    // Store in local storage (permanent)
    await saveToLocalStorage(userId, data);
  }


  // ============== LOCAL STORAGE OPERATIONS (Persistent) ==============

  Future<File> _getStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }

  Future<void> saveToLocalStorage(String userId, Map<String, dynamic> data) async {
    try {
      final file = await _getStorageFile();
      
      // Read existing storage
      Map<String, dynamic> allData = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        allData = jsonDecode(contents) as Map<String, dynamic>;
      }

      allData[userId] = {
        'data': data,
        'savedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(allData));
      debugPrint('Saved to local storage: $userId');
    } catch (e) {
      debugPrint('Error writing to local storage: $e');
    }
  }

  /// Get from permanent local storage
  Future<Map<String, dynamic>?> getFromLocalStorage(String userId) async {
    try {
      final file = await _getStorageFile();
      
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final allData = jsonDecode(contents) as Map<String, dynamic>;
      
      final userData = allData[userId];
      if (userData == null) return null;

      return userData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading from local storage: $e');
      return null;
    }
  }

  /// Remove from permanent local storage
  Future<void> removeFromLocalStorage(String userId) async {
    try {
      final file = await _getStorageFile();
      
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final allData = jsonDecode(contents) as Map<String, dynamic>;
      
      allData.remove(userId);
      
      await file.writeAsString(jsonEncode(allData));
      debugPrint('Removed from local storage: $userId');
    } catch (e) {
      debugPrint('Error removing from local storage: $e');
    }
  }


  /// Update existing data without replacing
  Future<void> updateLocalStorage(String userId, Map<String, dynamic> newData) async {
    try {
      final existing = await getFromLocalStorage(userId);
      
      if (existing == null) {
        // If doesn't exist, just save
        await saveToLocalStorage(userId, newData);
        return;
      }

      // Merge existing with new data
      final merged = {...existing, ...newData};
      
      final file = await _getStorageFile();
      final contents = await file.readAsString();
      final allData = jsonDecode(contents) as Map<String, dynamic>;
      
      allData[userId] = {
        'data': merged,
        'savedAt': allData[userId]['savedAt'], // Keep original save time
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(jsonEncode(allData));
      
      // Update cache too
      _cache[userId] = merged;
      
      debugPrint('Updated local storage: $userId');
    } catch (e) {
      debugPrint('Error updating local storage: $e');
    }
  }

  // ============== UTILITIES ==============

  /// Load all data from storage into cache on app start
  Future<void> preloadCacheFromStorage() async {
    try {
      final file = await _getStorageFile();
      
      if (!await file.exists()) {
        debugPrint('No storage file to preload');
        return;
      }

      final contents = await file.readAsString();
      final allData = jsonDecode(contents) as Map<String, dynamic>;
      
      int loaded = 0;
      for (var entry in allData.entries) {
        final userId = entry.key;
        final userData = entry.value as Map<String, dynamic>;
        final data = userData['data'] as Map<String, dynamic>;
        
        _cache[userId] = data;
        loaded++;
      }
      
      debugPrint('Preloaded $loaded users into cache');
    } catch (e) {
      debugPrint(' Error preloading cache: $e');
    }
  }



  void clearCache() => _cache.clear();

  Future<void> clearLocalStorage() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) await file.delete();
      debugPrint('Local storage cleared');
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}