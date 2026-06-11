import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/product_model.dart';
import 'package:gold_taxi/models/service_model.dart';
import 'package:gold_taxi/models/event_model.dart';
import 'package:gold_taxi/models/post_model.dart';

import 'package:gold_taxi/core/constants/api_constants.dart';

class SearchResult {
  final List<ProductModel> products;
  final List<ServiceModel> services;
  final List<EventModel> events;
  final List<PostModel> posts;

  const SearchResult({
    this.products = const [],
    this.services = const [],
    this.events = const [],
    this.posts = const [],
  });

  bool get isEmpty => products.isEmpty && services.isEmpty && events.isEmpty && posts.isEmpty;
}

class SearchRepository {
  final ApiService _apiService;
  final Connectivity _connectivity;
  static const String _boxName = 'search_history_box';

  SearchRepository(this._apiService, this._connectivity);

  /// Search across all categories
  Future<SearchResult> searchAll(String query) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) || query.trim().isEmpty) {
      return const SearchResult();
    }

    try {
      // Parallel API search calls using ApiConstants paths
      final futures = await Future.wait([
        _apiService.get(ApiConstants.productsEndpoint, queryParameters: {'search': query, 'per_page': 5}),
        _apiService.get(ApiConstants.servicesEndpoint, queryParameters: {'search': query, 'per_page': 5}),
        _apiService.get(ApiConstants.eventsEndpoint, queryParameters: {'search': query, 'per_page': 5}),
        _apiService.get(ApiConstants.postsEndpoint, queryParameters: {'search': query, 'per_page': 5}),
      ]);

      final productsJson = futures[0] as List? ?? [];
      final servicesJson = futures[1] as List? ?? [];
      final eventsJson = futures[2] as List? ?? [];
      final postsJson = futures[3] as List? ?? [];

      final products = productsJson.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
      final services = servicesJson.map((json) => ServiceModel.fromJson(json as Map<String, dynamic>)).toList();
      final events = eventsJson.map((json) => EventModel.fromJson(json as Map<String, dynamic>)).toList();
      final posts = postsJson.map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();

      return SearchResult(
        products: products,
        services: services,
        events: events,
        posts: posts,
      );
    } catch (_) {
      return const SearchResult();
    }
  }

  /// Get search history terms
  Future<List<String>> getSearchHistory() async {
    final box = await Hive.openBox(_boxName);
    return (box.get('history') as List?)?.cast<String>() ?? [];
  }

  /// Add term to search history
  Future<void> addToSearchHistory(String term) async {
    if (term.trim().isEmpty) return;
    final box = await Hive.openBox(_boxName);
    final currentHistory = (box.get('history') as List?)?.cast<String>() ?? [];
    currentHistory.remove(term); // remove duplicate
    currentHistory.insert(0, term); // add to top
    if (currentHistory.length > 10) {
      currentHistory.removeLast(); // limit size
    }
    await box.put('history', currentHistory);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    final box = await Hive.openBox(_boxName);
    await box.delete('history');
  }
}
