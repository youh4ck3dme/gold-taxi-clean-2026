import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  ChatCubit(this._chatRepository) : super(ChatInitial());

  void initChat(String rideId) {
    emit(ChatLoading());

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository
        .getMessagesStream(rideId)
        .listen(
          (messages) {
            emit(ChatLoaded(messages: messages));
          },
          onError: (error) {
            emit(ChatError('Nepodarilo sa načítať chat: $error'));
          },
        );
  }

  Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _chatRepository.sendMessage(
        rideId: rideId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
      );
    } catch (e) {
      // In a real app we'd handle sending errors (e.g. show a toast)
      emit(ChatError('Nepodarilo sa odoslať správu: $e'));
    }
  }

  Future<String?> initiateMaskedCall({
    required String rideId,
    required String callerId,
    required String receiverId,
  }) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isCalling: true));

      try {
        final proxyNumber = await _chatRepository.triggerMaskedCall(
          rideId: rideId,
          callerId: callerId,
          receiverId: receiverId,
        );
        return proxyNumber;
      } catch (e) {
        emit(ChatError('Nepodarilo sa spojiť hovor: $e'));
        return null;
      } finally {
        if (state is ChatLoaded) {
          emit((state as ChatLoaded).copyWith(isCalling: false));
        }
      }
    }
    return null;
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
