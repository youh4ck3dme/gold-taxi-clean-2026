enum RideStatus {
  requested,
  accepted,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

extension RideStatusExtension on RideStatus {
  String get dbValue {
    switch (this) {
      case RideStatus.requested:
        return 'requested';
      case RideStatus.accepted:
        return 'accepted';
      case RideStatus.driverArriving:
        return 'driver_arriving';
      case RideStatus.inProgress:
        return 'in_progress';
      case RideStatus.completed:
        return 'completed';
      case RideStatus.cancelled:
        return 'cancelled';
    }
  }

  static RideStatus fromDbValue(String value) {
    switch (value) {
      case 'requested':
        return RideStatus.requested;
      case 'accepted':
        return RideStatus.accepted;
      case 'driver_arriving':
        return RideStatus.driverArriving;
      case 'in_progress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.requested;
    }
  }

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
