import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'direct_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<DirectChat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final result = await _chatService.getChatList();
      if (result['success']) {
        final chatList = result['data'] as List;
        setState(() {
          _chats = chatList.map((item) => DirectChat.fromJson(item)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar chat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToChat(DirectChat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          barberId: chat.otherUser.id,
          barberName: chat.otherUser.nama,
          barberPhoto: chat.otherUser.profilePhoto,
          barberSpesialisasi: chat.otherUser.spesialisasi,
        ),
      ),
    ).then((_) => _loadChats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHAT'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(child: Text('Belum ada percakapan'))
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: chat.otherUser.profilePhoto != null
                            ? NetworkImage(chat.otherUser.profilePhoto!)
                            : null,
                        child: chat.otherUser.profilePhoto == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(chat.otherUser.nama),
                      subtitle: Text(chat.lastMessage ?? ''),
                      trailing: chat.unreadCount > 0
                          ? CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Text(
                                '${chat.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _navigateToChat(chat),
                    );
                  },
                ),
    );
  }
}
