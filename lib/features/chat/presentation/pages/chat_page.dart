import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/chat_cubit.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';

class ChatPage extends StatefulWidget {
  final String rideId;
  final String driverId;
  final String driverName;

  const ChatPage({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatCubit _chatCubit;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _chatCubit = getIt<ChatCubit>()..initChat(widget.rideId);

    // Get current user ID (assuming AuthCubit has it)
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _chatCubit.sendMessage(
      rideId: widget.rideId,
      senderId: _currentUserId,
      receiverId: widget.driverId,
      message: _messageController.text.trim(),
    );

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initiateMaskedCall() async {
    final proxyNumber = await _chatCubit.initiateMaskedCall(
      rideId: widget.rideId,
      callerId: _currentUserId,
      receiverId: widget.driverId,
    );

    if (proxyNumber != null && mounted) {
      final Uri url = Uri.parse('tel:$proxyNumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nepodarilo sa otvoriť vytáčanie pre číslo $proxyNumber',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.driverName),
          actions: [
            BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is ChatLoaded && state.isCalling) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Spúšťam maskovaný hovor...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              builder: (context, state) {
                bool isCalling = false;
                if (state is ChatLoaded) {
                  isCalling = state.isCalling;
                }
                return IconButton(
                  icon: isCalling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.phone),
                  onPressed: isCalling ? null : _initiateMaskedCall,
                  tooltip: 'Maskovaný hovor',
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading || state is ChatInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatError) {
                    return Center(child: Text(state.message));
                  } else if (state is ChatLoaded) {
                    final messages = state.messages;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Zatiaľ žiadne správy.\nNapíšte vodičovi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == _currentUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.black : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : null,
                                bottomLeft: !isMe
                                    ? const Radius.circular(4)
                                    : null,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.message,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(msg.createdAt),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Quick Replies
            Container(
              height: 48,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children:
                    [
                      'Som tu',
                      'Meškám 2 minúty',
                      'Stojím na dohodnutom mieste',
                      'Už idem',
                      'Mám veľký kufor',
                    ].map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            reply,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          backgroundColor: Colors.grey[100],
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onPressed: () {
                            _chatCubit.sendMessage(
                              rideId: widget.rideId,
                              senderId: _currentUserId,
                              receiverId: widget.driverId,
                              message: reply,
                            );
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    offset: Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Správa...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatCubit.close();
    super.dispose();
  }
}
