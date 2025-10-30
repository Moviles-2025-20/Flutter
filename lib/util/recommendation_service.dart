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
  void Function(Map<String, dynamic> freshData)? _onRecommendationsUpdated;

  Future<Map<String, dynamic>?> getRecommendations(String userId) async {
    final cached = await _storage.getRecommendations(userId);
    if (cached != null) {
      _refreshRecommendationsInBackground(userId);
      return cached;
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

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (!hasInternet) {
      debugPrint('Skipping background refresh — no internet connection');
      return;
    }

    compute(_backgroundFetchAndStore, userId)
        .then((freshData) async {
          if (freshData != null) {
            debugPrint('Background refresh completed');
            await _storage.storeRecommendations(userId, freshData);
            // Optionally notify listeners or refresh UI
            _onRecommendationsUpdated?.call(freshData);
          } else {
            debugPrint('Background fetch returned null data');
          }
        })
        .catchError((e) => debugPrint('Background refresh failed: $e'));
  }
}

Future<Map<String, dynamic>?> _backgroundFetchAndStore(String userId) async {
  final service = RecommendationService();
  return await service.getRecommendations(userId);
}



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

//Class for Cache
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