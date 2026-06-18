import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/models/faq_model.dart';

class FaqRepository {
  final SupabaseClient _supabase;
  final Connectivity _connectivity;
  static const String _boxName = 'faqs_cache_box';

  FaqRepository(this._supabase, this._connectivity);

  /// Fetch FAQs from Supabase or fallback to local cache
  Future<List<FaqModel>> getFaqs() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        // Note: .neq('id', '') is a temporary compatibility guard.
        // The faqs table does not have an is_active field in the current schema.
        // RLS policy "Anyone can read faqs" allows public read access.
        // TODO: Consider adding is_active boolean field for soft-deletion.
        final response = await _supabase
            .from('faqs')
            .select()
            .neq('id', '')
            .order('order_index', ascending: true);
            
        final faqs = (response as List)
            .map((json) => FaqModel.fromSupabaseJson(json as Map<String, dynamic>))
            .toList();
            
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
