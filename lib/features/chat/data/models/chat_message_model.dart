import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final String id;
  final String rideId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    rideId,
    senderId,
    receiverId,
    message,
    createdAt,
  ];
}
