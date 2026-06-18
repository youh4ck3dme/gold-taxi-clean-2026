part of 'chat_cubit.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessageModel> messages;
  final bool isCalling;

  const ChatLoaded({this.messages = const [], this.isCalling = false});

  ChatLoaded copyWith({List<ChatMessageModel>? messages, bool? isCalling}) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isCalling: isCalling ?? this.isCalling,
    );
  }

  @override
  List<Object?> get props => [messages, isCalling];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
