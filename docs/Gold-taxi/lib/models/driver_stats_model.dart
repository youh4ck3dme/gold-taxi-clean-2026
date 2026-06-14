import 'package:equatable/equatable.dart';

class DriverStatsModel extends Equatable {
  final int ridesCount;
  final double totalEarnings;
  final double averageRating;

  const DriverStatsModel({
    required this.ridesCount,
    required this.totalEarnings,
    required this.averageRating,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) {
    return DriverStatsModel(
      ridesCount: json['ridesCount'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num? ?? 0).toDouble(),
      averageRating: (json['averageRating'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ridesCount': ridesCount,
      'totalEarnings': totalEarnings,
      'averageRating': averageRating,
    };
  }

  @override
  List<Object?> get props => [ridesCount, totalEarnings, averageRating];
}
