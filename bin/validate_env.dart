// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ ERROR: .env file does not exist in root directory.');
    exit(1);
  }

  final content = envFile.readAsStringSync();
  final requiredKeys = [
    'baseUrl',
  ];

  var missing = false;
  for (final key in requiredKeys) {
    if (!content.contains(key)) {
      print('❌ ERROR: Missing required configuration key "$key" in .env');
      missing = true;
    }
  }

  if (missing) {
    exit(1);
  }

  print('✅ SUCCESS: .env configuration is valid and complete.');
  exit(0);
}
