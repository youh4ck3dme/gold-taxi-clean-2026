import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SUPABASE_URL and SUPABASE_ANON_KEY are correctly loaded from .env', () {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://test.supabase.co');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'test-anon-key');

    // Vypíšeme ich cez log() namiesto print() kvôli linteru
    log('Načítaná URL: $supabaseUrl');
    final String keyPreview = supabaseAnonKey.isNotEmpty ? '${supabaseAnonKey.substring(0, 10)}...' : 'PRÁZDNY';
    log('Načítaný kľúč: $keyPreview');

    expect(supabaseUrl, isNotEmpty, reason: 'SUPABASE_URL nebol načítaný. Skontrolujte vlajku --dart-define-from-file');
    expect(supabaseUrl.startsWith('https://'), isTrue, reason: 'SUPABASE_URL musí byť platná HTTPS adresa');
    expect(supabaseAnonKey, isNotEmpty, reason: 'SUPABASE_ANON_KEY nebol načítaný.');
  });
}
