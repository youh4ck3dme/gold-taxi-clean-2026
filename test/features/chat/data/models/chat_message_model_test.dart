import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/features/chat/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    final tModel = ChatMessageModel(
      id: 'msg_1',
      rideId: 'ride_1',
      senderId: 'driver_test',
      receiverId: 'customer_1',
      message: 'Už som tu',
      createdAt: DateTime.utc(2026, 6, 14, 15, 0, 0).toLocal(),
    );

    test('toJson vráti správnu mapu', () {
      final json = tModel.toJson();
      expect(json['id'], 'msg_1');
      expect(json['ride_id'], 'ride_1');
      expect(json['sender_id'], 'driver_test');
      expect(json['receiver_id'], 'customer_1');
      expect(json['message'], 'Už som tu');
      expect(json['created_at'], tModel.createdAt.toUtc().toIso8601String());
    });

    test('fromJson správne naparsuje objekt', () {
      final json = {
        'id': 'msg_1',
        'ride_id': 'ride_1',
        'sender_id': 'driver_test',
        'receiver_id': 'customer_1',
        'message': 'Už som tu',
        'created_at': '2026-06-14T15:00:00.000Z',
      };

      final parsed = ChatMessageModel.fromJson(json);
      expect(parsed.id, 'msg_1');
      expect(parsed.rideId, 'ride_1');
      expect(parsed.message, 'Už som tu');
      expect(parsed.createdAt, DateTime.utc(2026, 6, 14, 15, 0, 0).toLocal());
    });
  });
}
