import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/models/faq_model.dart';

class FaqRepository {
  final ApiService _apiService;
  final Connectivity _connectivity;
  static const String _boxName = 'faqs_cache_box';

  FaqRepository(this._apiService, this._connectivity);

  /// Fetch FAQs from remote API or fallback to local cache
  Future<List<FaqModel>> getFaqs() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final faqs = await _apiService.getFAQs();
        await _cacheFaqs(faqs);
        return faqs;
      } catch (_) {
        return await _getCachedFaqs();
      }
    }

    return await _getCachedFaqs();
  }

  /// Cache FAQs locally
  Future<void> _cacheFaqs(List<FaqModel> faqs) async {
    final box = await Hive.openBox(_boxName);
    final faqsJson = faqs.map((faq) => faq.toJson()).toList();
    await box.put('faqs', faqsJson);
  }

  /// Get cached FAQs
  Future<List<FaqModel>> _getCachedFaqs() async {
    final box = await Hive.openBox(_boxName);
    final faqsJson = box.get('faqs') as List?;
    if (faqsJson != null) {
      return faqsJson
          .map((json) => FaqModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }
    return [];
  }
}
