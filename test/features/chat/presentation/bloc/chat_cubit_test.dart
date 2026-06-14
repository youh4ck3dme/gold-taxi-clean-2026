import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:gold_taxi/features/chat/data/repositories/chat_repository.dart';
import 'package:gold_taxi/features/chat/data/models/chat_message_model.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ChatCubit chatCubit;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    chatCubit = ChatCubit(mockChatRepository);
  });

  tearDown(() async {
    await chatCubit.close();
  });

  group('ChatCubit Tests', () {
    final testMessages = [
      ChatMessageModel(
        id: 'msg_1',
        rideId: 'ride_123',
        senderId: 'user_1',
        receiverId: 'user_2',
        message: 'Ahoj',
        createdAt: DateTime.now(),
      ),
      ChatMessageModel(
        id: 'msg_2',
        rideId: 'ride_123',
        senderId: 'user_2',
        receiverId: 'user_1',
        message: 'Som tu',
        createdAt: DateTime.now(),
      ),
    ];

    test('Initial state is ChatInitial', () {
      expect(chatCubit.state, isA<ChatInitial>());
    });

    test('initChat subscribes to messages stream and emits ChatLoaded', () async {
      final controller = StreamController<List<ChatMessageModel>>();
      when(() => mockChatRepository.getMessagesStream('ride_123'))
          .thenAnswer((_) => controller.stream);

      expectLater(
        chatCubit.stream,
        emitsInOrder([
          isA<ChatLoading>(),
          predicate<ChatState>((state) {
            if (state is! ChatLoaded) return false;
            expect(state.messages, testMessages);
            expect(state.isCalling, false);
            return true;
          }),
        ]),
      );

      chatCubit.initChat('ride_123');
      controller.add(testMessages);
      await controller.close();
    });

    test('initChat emits ChatError on stream error', () async {
      final controller = StreamController<List<ChatMessageModel>>();
      when(() => mockChatRepository.getMessagesStream('ride_123'))
          .thenAnswer((_) => controller.stream);

      expectLater(
        chatCubit.stream,
        emitsInOrder([
          isA<ChatLoading>(),
          isA<ChatError>(),
        ]),
      );

      chatCubit.initChat('ride_123');
      controller.addError(Exception('Firebase error'));
      await controller.close();
    });

    test('sendMessage calls repository and does not emit error on success', () async {
      when(() => mockChatRepository.sendMessage(
            rideId: any(named: 'rideId'),
            senderId: any(named: 'senderId'),
            receiverId: any(named: 'receiverId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => {});

      await chatCubit.sendMessage(
        rideId: 'ride_123',
        senderId: 'user_1',
        receiverId: 'user_2',
        message: 'Som tu',
      );

      verify(() => mockChatRepository.sendMessage(
            rideId: 'ride_123',
            senderId: 'user_1',
            receiverId: 'user_2',
            message: 'Som tu',
          )).called(1);
    });

    test('initiateMaskedCall sets isCalling true then false', () async {
      chatCubit.emit(ChatLoaded(messages: testMessages, isCalling: false));

      when(() => mockChatRepository.triggerMaskedCall(
            rideId: any(named: 'rideId'),
            callerId: any(named: 'callerId'),
            receiverId: any(named: 'receiverId'),
          )).thenAnswer((_) async => '+421944987654');

      expectLater(
        chatCubit.stream,
        emitsInOrder([
          predicate<ChatState>((state) => state is ChatLoaded && state.isCalling == true),
          predicate<ChatState>((state) => state is ChatLoaded && state.isCalling == false),
        ]),
      );

      await chatCubit.initiateMaskedCall(
        rideId: 'ride_123',
        callerId: 'user_1',
        receiverId: 'user_2',
      );

      verify(() => mockChatRepository.triggerMaskedCall(
            rideId: 'ride_123',
            callerId: 'user_1',
            receiverId: 'user_2',
          )).called(1);
    });
  });
}
