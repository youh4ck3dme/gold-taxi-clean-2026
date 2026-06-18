enum ServiceType { standard, comfort, premium }

class PricingService {
  static const double baseFare = 1.50;
  static const double pricePerKm = 0.90;
  static const double minimumFare = 3.50;

  static double calculateEstimate({
    required double distanceInKm,
    required ServiceType type,
    bool isAirport = false,
    bool isNight = false,
    double surgeMultiplier = 1.0,
  }) {
    double multiplier = 1.0;
    switch (type) {
      case ServiceType.standard:
        multiplier = 1.0;
        break;
      case ServiceType.comfort:
        multiplier = 1.3;
        break;
      case ServiceType.premium:
        multiplier = 1.8;
        break;
    }

    double fare =
        (baseFare + (distanceInKm * pricePerKm)) * multiplier * surgeMultiplier;

    if (isAirport) fare += 5.0; // Airport fee
    if (isNight) fare += 2.0; // Night fee

    return fare < minimumFare ? minimumFare : fare;
  }
}
