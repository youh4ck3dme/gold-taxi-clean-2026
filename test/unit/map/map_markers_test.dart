import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/features/map/presentation/widgets/platform_map_widget.dart';

void main() {
  group('MapMarkerData Tests', () {
    test('MapMarkerData has correct fields for demo driver', () {
      const marker = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Ján Novák',
        snippet: 'Škoda Octavia • BA-123GT',
        isAvailable: true,
        rotation: 45.0,
      );

      expect(marker.id, 'demo_driver_jan_novak');
      expect(marker.latitude, 48.1486);
      expect(marker.longitude, 17.1077);
      expect(marker.title, 'Ján Novák');
      expect(marker.snippet, 'Škoda Octavia • BA-123GT');
      expect(marker.isAvailable, true);
    });

    test('MapMarkerData equality works based on id', () {
      const marker1 = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Ján Novák',
        snippet: 'Škoda Octavia • BA-123GT',
        isAvailable: true,
      );

      const marker2 = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Ján Novák',
        snippet: 'Škoda Octavia • BA-123GT',
        isAvailable: true,
      );

      const marker3 = MapMarkerData(
        id: 'different_driver',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Other Driver',
      );

      expect(marker1, marker2);
      expect(marker1 == marker3, false);
    });

    test('MapMarkerData hashCode is based on id', () {
      const marker1 = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Ján Novák',
      );

      const marker2 = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 0,
        longitude: 0,
        title: 'Different',
      );

      expect(marker1.hashCode, marker2.hashCode);
    });
  });

  group('PlatformMapWidget Tests', () {
    test('PlatformMapWidget can be constructed with markers', () {
      final markers = {
        const MapMarkerData(
          id: 'demo_driver_jan_novak',
          latitude: 48.1486,
          longitude: 17.1077,
          title: 'Ján Novák',
          snippet: 'Škoda Octavia • BA-123GT',
          isAvailable: true,
        ),
      };

      final widget = PlatformMapWidget(
        latitude: 48.1486,
        longitude: 17.1077,
        zoom: 14.0,
        markers: markers,
      );

      expect(widget.latitude, 48.1486);
      expect(widget.longitude, 17.1077);
      expect(widget.zoom, 14.0);
      expect(widget.markers, markers);
    });

    test('Marker data for demo driver has taxi info in snippet', () {
      const marker = MapMarkerData(
        id: 'demo_driver_jan_novak',
        latitude: 48.1486,
        longitude: 17.1077,
        title: 'Ján Novák',
        snippet: 'Škoda Octavia • BA-123GT',
        isAvailable: true,
      );

      expect(marker.title, 'Ján Novák');
      expect(marker.snippet, contains('Škoda Octavia'));
      expect(marker.snippet, contains('BA-123GT'));
    });
  });
}
