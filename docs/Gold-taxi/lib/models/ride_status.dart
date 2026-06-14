enum RideStatus {
  requested,
  accepted,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

extension RideStatusExtension on RideStatus {
  String get label {
    switch (this) {
      case RideStatus.requested:
        return 'Vyžiadané';
      case RideStatus.accepted:
        return 'Prijaté vodičom';
      case RideStatus.driverArriving:
        return 'Vodič prichádza';
      case RideStatus.inProgress:
        return 'Prebieha jazda';
      case RideStatus.completed:
        return 'Dokončené';
      case RideStatus.cancelled:
        return 'Zrušené';
    }
  }

  bool get canCancel => 
    this == RideStatus.requested || 
    this == RideStatus.accepted || 
    this == RideStatus.driverArriving;
}
