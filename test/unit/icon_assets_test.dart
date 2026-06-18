import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Icon Assets', () {
    test('Main icon PNG exists', () {
      expect(
        File('assets/icon/icon.png').existsSync(),
        isTrue,
        reason: 'assets/icon/icon.png must exist',
      );
    });

    test('Android mipmap icons exist', () {
      final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
      for (final d in densities) {
        final f = File('android/app/src/main/res/mipmap-$d/ic_launcher.png');
        expect(
          f.existsSync(),
          isTrue,
          reason: 'Missing: mipmap-$d/ic_launcher.png',
        );
      }
    });

    test('Web favicon icons exist', () {
      final icons = ['web/icons/Icon-192.png', 'web/icons/Icon-512.png'];
      for (final path in icons) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing web icon: $path',
        );
      }
    });

    test('iOS AppIcon assets exist', () {
      final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'iOS AppIcon.appiconset directory missing',
      );
      expect(
        dir.listSync().isNotEmpty,
        isTrue,
        reason: 'iOS AppIcon.appiconset is empty',
      );
    });
  });
}
