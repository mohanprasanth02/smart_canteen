import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import '../../chat/data/chat_provider.dart';

class AdminChatHubScreen extends ConsumerStatefulWidget {
  const AdminChatHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminChatHubScreen> createState() => _AdminChatHubScreenState();
}

class _AdminChatHubScreenState extends ConsumerState<AdminChatHubScreen> {
  Map<String, dynamic>? _selectedRoom;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text, String role) {
    if (text.trim().isEmpty || _selectedRoom == null) return;
    ref.read(chatStateProvider.notifier).sendMessage(text.trim(), role);
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRoomsAsync = ref.watch(activeChatRoomsProvider);
    final chatState = ref.watch(chatStateProvider);
    final authState = ref.watch(authStateProvider);
    final userRole = authState.role;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.messages.isNotEmpty && _selectedRoom != null) {
        _scrollToBottom();
      }
    });

    final isRoomClosed = chatState.activeRoom != null && chatState.activeRoom!['status'] == 'closed';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Support Chat Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 700;

          if (isLargeScreen) {
            // Master-Detail Split Screen for tablet/desktop
            return Row(
              children: [
                // Master (Left Pane): Rooms List
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.darkBorder)),
                    ),
                    child: _buildRoomsList(activeRoomsAsync, chatState),
                  ),
                ),

                // Detail (Right Pane): Chat Session
                Expanded(
                  child: _selectedRoom == null
                      ? const Center(
                          child: Text(
                            'Select a chat from the left pane to reply.',
                            style: TextStyle(color: AppColors.textDarkSecondary),
                          ),
                        )
                      : _buildChatSession(chatState, userRole, isRoomClosed),
                ),
              ],
            );
          } else {
            // Single Pane for Mobile (Normal Navigation flow)
            return _selectedRoom == null
                ? _buildRoomsList(activeRoomsAsync, chatState)
                : WillPopScope(
                    onWillPop: () async {
                      setState(() {
                        _selectedRoom = null;
                      });
                      return false;
                    },
                    child: Scaffold(
                      backgroundColor: AppColors.darkBackground,
                      appBar: AppBar(
                        title: Text(
                          _selectedRoom!['student_name'] ?? 'Student Support',
                          style: const TextStyle(fontSize: 16),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedRoom = null;
                            });
                          },
                        ),
                      ),
                      body: _buildChatSession(chatState, userRole, isRoomClosed),
                    ),
                  );
          }
        },
      ),
    );
  }

  Widget _buildRoomsList(AsyncValue<List<dynamic>> activeRoomsAsync, ChatState chatState) {
    return activeRoomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Center(
            child: Text(
              'No active support chats.',
              style: TextStyle(color: AppColors.textDarkSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(activeChatRoomsProvider.future),
          color: AppColors.primaryNeon,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isSelected = _selectedRoom != null && _selectedRoom!['id'] == room['id'];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryNeon.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryNeon : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppColors.primaryNeon : AppColors.darkSurface,
                    child: Text(
                      (room['student_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    room['student_name'] ?? 'Unknown Student',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      if (room['order_id'] != null)
                        Text(
                          'Order: ${room['order_id']}',
                          style: const TextStyle(color: AppColors.primaryNeon, fontSize: 11),
                        ),
                      Text(
                        'Opened at ${_formatDateTime(room['created_at'])}',
                        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedRoom = room;
                    });
                    ref.read(chatStateProvider.notifier).selectAdminRoom(room);
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
      error: (err, _) => Center(
        child: Text(
          'Error loading chats: $err',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildChatSession(ChatState chatState, String userRole, bool isClosed) {
    return Column(
      children: [
        // Action Bar for admin (Refund & Ticket options)
        if (!isClosed)
          Container(
            color: AppColors.darkCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Support Controls',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.2),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        // Quick Action: Close Ticket
                        ref.read(chatStateProvider.notifier).closeActiveRoom().then((_) {
                          ref.invalidate(activeChatRoomsProvider);
                          setState(() {
                            _selectedRoom = null;
                          });
                        });
                      },
                      icon: const Icon(Icons.cancel_presentation_rounded, size: 16),
                      label: const Text('Close Session', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Chat Messages List
        Expanded(
          child: chatState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    final isSystem = msg['sender_role'] == 'system';
                    final isMe = msg['sender_role'] == 'admin';

                    if (isSystem) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkBorder.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['message'],
                            style: const TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.70,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primaryNeon.withOpacity(0.2)
                                    : AppColors.darkCard,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(isMe ? 14 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 14),
                                ),
                                border: Border.all(
                                  color: isMe ? AppColors.primaryNeon : AppColors.darkBorder,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                msg['message'],
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatTime(msg['created_at']),
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Text input bar
        if (isClosed)
          SafeArea(
            child: Container(
              width: double.infinity,
              color: AppColors.darkCard,
              padding: const EdgeInsets.all(14),
              child: const Center(
                child: Text(
                  'This support session has been closed.',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Reply to student...',
                        hintStyle: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primaryNeon),
                        ),
                      ),
                      onSubmitted: (val) => _sendMessage(val, userRole),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryNeon,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      onPressed: () => _sendMessage(_messageController.text, userRole),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final date = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final date = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}
