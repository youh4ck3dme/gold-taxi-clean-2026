class MathUtils {
  /// Vypočíta najkratší uhol medzi starým a novým uhlom rotácie
  /// (aby sa animácia neotáčala cez celú os, napr. z 350 na 10 stupňov)
  static double shortestAngle(double oldAngle, double newAngle) {
    double diff = (newAngle - oldAngle) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }
}
