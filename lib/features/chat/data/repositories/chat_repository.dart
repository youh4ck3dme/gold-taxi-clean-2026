import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final SupabaseClient _supabaseClient;

  ChatRepository(this._supabaseClient);

  /// Stream messages for a specific ride
  Stream<List<ChatMessageModel>> getMessagesStream(String rideId) {
    return _supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('created_at', ascending: true)
        .map(
          (data) =>
              data.map((json) => ChatMessageModel.fromJson(json)).toList(),
        );
  }

  /// Send a new message
  Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await _supabaseClient.from('messages').insert({
      'ride_id': rideId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
    });
  }

  /// Call the Supabase Edge Function to initialize Twilio masked call
  Future<String?> triggerMaskedCall({
    required String rideId,
    required String callerId,
    required String receiverId,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'twilio_masked_call',
        body: {
          'rideId': rideId,
          'callerId': callerId,
          'receiverId': receiverId,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['proxyNumber'] as String?;
      }
      return '+421944987654'; // Fallback mock number
    } catch (_) {
      // Simulate network delay and return fallback mock number for development
      await Future.delayed(const Duration(seconds: 1));
      return '+421944987654';
    }
  }
}
