import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/utils/math_utils.dart';

void main() {
  group('MathUtils.shortestAngle', () {
    test('z 10 na 20 by malo byt +10', () {
      expect(MathUtils.shortestAngle(10, 20), 10);
    });

    test('z 350 na 10 by malo byt +20 (najkratsia cesta cez nulu)', () {
      expect(MathUtils.shortestAngle(350, 10), 20);
    });

    test('z 10 na 350 by malo byt -20 (najkratsia cesta dozadu)', () {
      expect(MathUtils.shortestAngle(10, 350), -20);
    });

    test('z 180 na 190 by malo byt +10', () {
      expect(MathUtils.shortestAngle(180, 190), 10);
    });

    test('z 190 na 180 by malo byt -10', () {
      expect(MathUtils.shortestAngle(190, 180), -10);
    });
  });
}
