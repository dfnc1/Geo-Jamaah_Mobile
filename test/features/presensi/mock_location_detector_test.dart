import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_jamaah/features/presensi/domain/mock_location_detector.dart';

Position createTestPosition({
  double latitude = -7.9666,
  double longitude = 112.6326,
  double accuracy = 15.0,
  bool isMocked = false,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    isMocked: isMocked,
  );
}

class FakeMockLocationDetector implements MockLocationDetector {
  bool returnValue;
  FakeMockLocationDetector({this.returnValue = false});

  @override
  Future<bool> isMockLocation(Position position) async {
    return returnValue || position.isMocked;
  }
}

void main() {
  group('DefaultMockLocationDetector', () {
    test('Position.isMocked true menghasilkan true', () async {
      final detector = DefaultMockLocationDetector(
        checkSafeDevice: () async => false,
      );
      final posMocked = createTestPosition(isMocked: true);

      final result = await detector.isMockLocation(posMocked);
      expect(result, true);
    });

    test('safe_device true menghasilkan true meskipun Position.isMocked false', () async {
      final detector = DefaultMockLocationDetector(
        checkSafeDevice: () async => true,
      );
      final posNormal = createTestPosition(isMocked: false);

      final result = await detector.isMockLocation(posNormal);
      expect(result, true);
    });

    test('keduanya false menghasilkan false', () async {
      final detector = DefaultMockLocationDetector(
        checkSafeDevice: () async => false,
      );
      final posNormal = createTestPosition(isMocked: false);

      final result = await detector.isMockLocation(posNormal);
      expect(result, false);
    });

    test('exception dari safe_device fallback ke position.isMocked tanpa melempar error', () async {
      final detector = DefaultMockLocationDetector(
        checkSafeDevice: () async => throw Exception('platform error'),
      );

      expect(await detector.isMockLocation(createTestPosition(isMocked: false)), false);
      expect(await detector.isMockLocation(createTestPosition(isMocked: true)), true);
    });
  });
}
