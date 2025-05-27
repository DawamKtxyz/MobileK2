class DirectChat {
  final int id;
  final int barberId;
  final int pelangganId;
  final DirectChatOtherUser otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String chatType;

  DirectChat({
    required this.id,
    required this.barberId,
    required this.pelangganId,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.chatType,
  });

  factory DirectChat.fromJson(Map<String, dynamic> json) {
    return DirectChat(
      id: json['id'],
      barberId: json['barber_id'],
      pelangganId: json['pelanggan_id'],
      otherUser: DirectChatOtherUser.fromJson(json['other_user']),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      chatType: json['chat_type'] ?? 'direct',
    );
  }
}

class DirectChatOtherUser {
  final int id;
  final String nama;
  final String? profilePhoto;
  final String? spesialisasi; // Untuk barber

  DirectChatOtherUser({
    required this.id,
    required this.nama,
    this.profilePhoto,
    this.spesialisasi,
  });

  factory DirectChatOtherUser.fromJson(Map<String, dynamic> json) {
    return DirectChatOtherUser(
      id: json['id'],
      nama: json['nama'],
      profilePhoto: json['profile_photo'],
      spesialisasi: json['spesialisasi'],
    );
  }
}

class DirectChatMessage {
  final int id;
  final String message;
  final String messageType;
  final String? filePath;
  final String senderType;
  final int senderId;
  final bool isRead;
  final DateTime createdAt;

  DirectChatMessage({
    required this.id,
    required this.message,
    required this.messageType,
    this.filePath,
    required this.senderType,
    required this.senderId,
    required this.isRead,
    required this.createdAt,
  });

  factory DirectChatMessage.fromJson(Map<String, dynamic> json) {
    return DirectChatMessage(
      id: json['id'],
      message: json['message'],
      messageType: json['message_type'] ?? 'text',
      filePath: json['file_path'],
      senderType: json['sender_type'],
      senderId: json['sender_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}