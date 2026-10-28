enum MarketplaceRole { renter, borrower }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  Map<String, Object> toMap() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        sentAt: DateTime.parse(map['sentAt'] as String),
      );
}

class ChatConversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String participantId;
  final String participantName;
  final MarketplaceRole myRole;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.participantId,
    required this.participantName,
    required this.myRole,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, Object> toMap() => {
        'id': id,
        'listingId': listingId,
        'listingTitle': listingTitle,
        'participantId': participantId,
        'participantName': participantName,
        'myRole': myRole.name,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((message) => message.toMap()).toList(),
      };

  factory ChatConversation.fromMap(Map<String, dynamic> map) => ChatConversation(
        id: map['id'] as String,
        listingId: map['listingId'] as String,
        listingTitle: map['listingTitle'] as String,
        participantId: map['participantId'] as String,
        participantName: map['participantName'] as String,
        myRole: MarketplaceRole.values.byName(map['myRole'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        messages: (map['messages'] as List<dynamic>)
            .map((message) => ChatMessage.fromMap(Map<String, dynamic>.from(message as Map)))
            .toList(),
      );

  ChatConversation withMessage(ChatMessage message) => ChatConversation(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        participantId: participantId,
        participantName: participantName,
        myRole: myRole,
        updatedAt: message.sentAt,
        messages: [...messages, message],
      );
}
