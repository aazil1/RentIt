import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../services/marketplace_scope.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  static final _dayFormat = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceScope.of(context);
    final conversations = store.conversations;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                      child: Icon(Icons.forum_outlined, size: 36, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Your inbox is ready', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    const Text(
                      'Message a renter from any listing, or reply to borrowers from your own listings. Conversations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final lastMessage = conversation.messages.isEmpty ? null : conversation.messages.last;
                final otherRole = conversation.myRole == MarketplaceRole.borrower ? 'Renter' : 'Borrower';
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        _initials(conversation.participantName),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(conversation.participantName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Text(_dayFormat.format(conversation.updatedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$otherRole · ${conversation.listingTitle}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(lastMessage?.text ?? 'Start a conversation about this listing', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
