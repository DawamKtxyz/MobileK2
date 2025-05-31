import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'direct_chat_screen.dart';
import '../utils/constants.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<DirectChat> _chats = [];
  bool _isLoading = true;
  String? _currentUserType; // ✅ Store user type as state

  @override
  void initState() {
    super.initState();
    _initializeUserType();
  }

  // ✅ Load user type first, then load chats
  Future<void> _initializeUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentUserType = prefs.getString('user_type');
      });
      await _loadChats();
    } catch (e) {
      print('Debug - Error initializing user type: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChats() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _chatService.getChatList();
      
      if (result['success']) {
        final chatList = result['data'] as List;
        setState(() {
          _chats = chatList.map((item) => DirectChat.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('Debug - Error loading chats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar chat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _getProfilePhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    
    // Use Constants.buildProfilePhotoUrl for consistency
    return Constants.buildProfilePhotoUrl(photoPath);
  }

  // ✅ Fixed navigation with proper user type handling
  void _navigateToChat(DirectChat chat) {
    if (_currentUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User type not loaded')),
      );
      return;
    }

    final bool isCurrentUserBarber = _currentUserType == 'barber';
    
    // ✅ Fix: Use correct IDs based on current user type
    final int targetUserId = isCurrentUserBarber ? chat.pelangganId : chat.barberId;
    final String targetUserType = isCurrentUserBarber ? 'pelanggan' : 'barber';
    
    print('Debug - Navigation Info:');
    print('Current User Type: $_currentUserType');
    print('Is Current User Barber: $isCurrentUserBarber');
    print('Target User ID: $targetUserId');
    print('Target User Type: $targetUserType');
    print('Chat - Barber ID: ${chat.barberId}, Pelanggan ID: ${chat.pelangganId}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          userId: targetUserId,
          userName: chat.otherUser.nama,
          userPhoto: chat.otherUser.profilePhoto,
          userSpesialisasi: chat.otherUser.spesialisasi,
          userType: targetUserType,
        ),
      ),
    ).then((_) => _loadChats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return _buildChatItem(chat);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada percakapan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUserType == 'barber'
                ? 'Percakapan dengan pelanggan akan muncul di sini'
                : 'Mulai percakapan dengan barber untuk bertanya tentang layanan',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(DirectChat chat) {
    final photoUrl = _getProfilePhotoUrl(chat.otherUser.profilePhoto);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  _currentUserType == 'barber' ? Icons.person : Icons.content_cut,
                  color: Theme.of(context).primaryColor,
                )
              : null,
        ),
        title: Text(
          chat.otherUser.nama,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.otherUser.spesialisasi != null) ...[
              Text(
                chat.otherUser.spesialisasi!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              chat.lastMessage ?? 'Belum ada pesan',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (chat.lastMessageAt != null)
              Text(
                _formatMessageTime(chat.lastMessageAt!),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _navigateToChat(chat),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}