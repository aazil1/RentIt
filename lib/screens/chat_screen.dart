import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../services/marketplace_scope.dart';
import '../services/marketplace_store.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  static final _timeFormat = DateFormat('h:mm a');

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(MarketplaceStore store) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    _messageController.clear();
    setState(() => _isSending = true);
    try {
      await store.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final matches = store.conversations.where((item) => item.id == widget.conversationId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: const Center(child: Text('This conversation is no longer available.')),
          );
        }
        final conversation = matches.first;
        final otherRole = conversation.myRole == MarketplaceRole.borrower
            ? MarketplaceRole.renter
            : MarketplaceRole.borrower;
        final messages = conversation.messages;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(_initials(conversation.participantName), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(conversation.participantName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${_roleLabel(otherRole)} · ${conversation.listingTitle}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFEAF2EE),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(
                  'About: ${conversation.listingTitle} · local demo chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF355A4D)),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55)),
                              const SizedBox(height: 12),
                              const Text('Start the conversation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                conversation.myRole == MarketplaceRole.borrower
                                    ? 'Ask ${conversation.participantName} about availability, pickup, or item details.'
                                    : 'Reply to the interested borrower about your listing.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          final isMine = message.senderId == 'local-user';
                          return _MessageBubble(
                            message: message,
                            isMine: isMine,
                            role: isMine ? conversation.myRole : otherRole,
                            time: _timeFormat.format(message.sentAt),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(store),
                          decoration: InputDecoration(
                            hintText: 'Message ${conversation.participantName}...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: _isSending ? null : () => _send(store),
                        icon: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _roleLabel(MarketplaceRole role) => role == MarketplaceRole.renter ? 'Renter' : 'Borrower';

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final MarketplaceRole role;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.role,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMine ? Theme.of(context).colorScheme.primary : Colors.white;
    final textColor = isMine ? Colors.white : Colors.black87;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: isMine ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${isMine ? 'You' : 'Demo user'} · ${role == MarketplaceRole.renter ? 'Renter' : 'Borrower'}', style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.72), fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(message.text, style: TextStyle(color: textColor, height: 1.3)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(time, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.65))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
