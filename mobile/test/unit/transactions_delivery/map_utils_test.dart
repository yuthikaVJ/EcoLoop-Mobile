// Transactions & delivery - map helpers
// (lib/features/transactions_delivery/presentation/utils/map_utils.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:eco_loop/features/transactions_delivery/presentation/utils/map_utils.dart';

void main() {
  group('parseCoordinates', () {
    test('reads "lat, lng" text from GPS and map taps', () {
      expect(parseCoordinates('6.927100, 79.861200'), const LatLng(6.9271, 79.8612));
      expect(parseCoordinates(' -33.5 ,151.2 '), const LatLng(-33.5, 151.2));
    });

    test('ignores addresses and out-of-range values', () {
      for (final value in [null, '', 'Colombo 07', '1,2,3', 'a, b', '91, 0', '0, 181', 'NaN, 1']) {
        expect(parseCoordinates(value), isNull, reason: '$value');
      }
    });
  });

  test('formatCoordinates writes 6 decimals that parse back', () {
    const point = LatLng(6.9271, 79.8612);
    expect(formatCoordinates(point), '6.927100, 79.861200');
    expect(parseCoordinates(formatCoordinates(point)), point);
  });

  group('decodePolyline', () {
    test('decodes the route geometry the backend returns', () {
      // Google's documented example polyline.
      final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points, const [LatLng(38.5, -120.2), LatLng(40.7, -120.95), LatLng(43.252, -126.453)]);
    });

    test('an empty route has no points', () {
      expect(decodePolyline(''), isEmpty);
    });

    test('a truncated route is rejected instead of drawing garbage', () {
      expect(() => decodePolyline('_p~iF~ps|U_'), throwsFormatException);
    });
  });
}
