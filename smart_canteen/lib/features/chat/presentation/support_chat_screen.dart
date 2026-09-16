import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import '../data/chat_provider.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  final int? orderId;
  final String? orderCode;

  const SupportChatScreen({
    Key? key,
    this.orderId,
    this.orderCode,
  }) : super(key: key);

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatStateProvider.notifier).initRoom(orderId: widget.orderId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    if (text.trim().isEmpty) return;
    ref.read(chatStateProvider.notifier).sendMessage(text.trim(), role);
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);
    final authState = ref.watch(authStateProvider);
    final userRole = authState.role;

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    final room = chatState.activeRoom;
    final isClosed = room != null && room['status'] == 'closed';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Canteen Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.orderCode != null)
              Text(
                'Regarding Order ${widget.orderCode}',
                style: const TextStyle(fontSize: 12, color: AppColors.primaryNeon),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (room != null && !isClosed)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.darkCard,
                    title: const Text('Close Ticket?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Are you sure you want to close this support ticket? This will mark your issue as resolved.',
                      style: TextStyle(color: AppColors.textDarkSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(chatStateProvider.notifier).closeActiveRoom();
                        },
                        child: const Text('Close Ticket', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
              label: const Text('Close', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon))
          : Column(
              children: [
                if (chatState.error != null)
                  Container(
                    color: AppColors.error.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    width: double.infinity,
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isSystem = msg['sender_role'] == 'system';
                      final isMe = msg['sender_role'] == 'student';

                      if (isSystem) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.darkBorder.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['message'],
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return _AnimatedChatBubble(
                        key: ValueKey(msg['id'] ?? index),
                        isMe: isMe,
                        index: index,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primaryNeon.withOpacity(0.85)
                                      : AppColors.darkCard,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                  border: Border.all(
                                    color: isMe
                                        ? AppColors.primaryNeon
                                        : AppColors.darkBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  msg['message'],
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(msg['created_at']),
                                style: const TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input bar
                if (isClosed)
                  SafeArea(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.darkCard,
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: Text(
                          'This support session has been closed.',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: const TextStyle(color: AppColors.textDarkSecondary),
                                filled: true,
                                fillColor: AppColors.darkCard,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: AppColors.darkBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: AppColors.darkBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: AppColors.primaryNeon),
                                ),
                              ),
                              onSubmitted: (val) => _sendMessage(val, userRole),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primaryNeon,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                splashColor: Colors.white30,
                                onTap: () => _sendMessage(_messageController.text, userRole),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
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

// ── Animated chat bubble (slides in from bottom/side) ─────────────
class _AnimatedChatBubble extends StatefulWidget {
  final bool isMe;
  final int index;
  final Widget child;

  const _AnimatedChatBubble({
    Key? key,
    required this.isMe,
    required this.index,
    required this.child,
  }) : super(key: key);

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.3 : -0.3, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
