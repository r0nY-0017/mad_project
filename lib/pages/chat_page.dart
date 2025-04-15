import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_chat_application/services/user_status_service.dart';
import 'package:simple_chat_application/services/friends_service.dart';
import 'package:simple_chat_application/pages/friends_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserStatusService _userStatusService = UserStatusService();

  bool _isLoading = true;
  bool _areFriends = false;

  @override
  void initState() {
    super.initState();
    _userStatusService.updateUserStatus(true);
    _checkFriendshipStatus();
    _markMessagesAsSeen();
  }

  @override
  void dispose() {
    _userStatusService.updateUserStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFriendshipStatus() async {
    print('Checking friendship between current user and ${widget.otherUserId}');

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      print('Current user doc exists: ${currentUserDoc.exists}');
      print('Other user doc exists: ${otherUserDoc.exists}');

      final friendsService = FriendsService();
      final areFriends = await friendsService.areFriends(widget.otherUserId);

      setState(() {
        _areFriends = areFriends;
        _isLoading = false;
      });
    } catch (e) {
      print('Friendship check failed: $e');
      setState(() {
        _isLoading = false;
        _areFriends = false;
      });
    }
  }

  Future<void> _markMessagesAsSeen() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      for (final doc in messages.docs) {
        final seenBy = List<String>.from(doc['seenBy'] ?? []);
        if (!seenBy.contains(currentUserId)) {
          await doc.reference.update({
            'seenBy': FieldValue.arrayUnion([currentUserId]),
          });
        }
      }

      print('Marked ${messages.docs.length} messages as seen');
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final currentUserId = _auth.currentUser?.uid;

    if (messageText.isEmpty || currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'seenBy': [],
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('Message sent: "$messageText"');

      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Send message failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.otherUsername,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        StreamBuilder<bool>(
          stream: _userStatusService.getUserStatusStream(widget.otherUserId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return const Text('Online', style: TextStyle(fontSize: 12));
            } else {
              return StreamBuilder<DateTime?>(
                stream: _userStatusService
                    .getUserLastSeenStream(widget.otherUserId),
                builder: (context, lastSeenSnapshot) {
                  if (lastSeenSnapshot.hasData &&
                      lastSeenSnapshot.data != null) {
                    return Text(
                      'Last seen ${DateFormat('hh:mm a').format(lastSeenSnapshot.data!)}',
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('Offline', style: TextStyle(fontSize: 12));
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Something went wrong'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!_areFriends) return _buildNotFriendsMessage();

        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return Center(
              child: Text('No messages yet. Start chatting!',
                  style: TextStyle(color: Colors.grey[600])));
        }

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
            final seenBy = List<String>.from(message['seenBy'] ?? []);
            final isSeen = seenBy.contains(widget.otherUserId);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                mainAxisAlignment: isCurrentUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? Colors.green.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message['timestamp'] != null
                                    ? DateFormat('hh:mm a').format(
                                        (message['timestamp'] as Timestamp)
                                            .toDate())
                                    : '',
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isSeen ? Icons.done_all : Icons.done,
                                  size: 16,
                                  color: isSeen ? Colors.blue : Colors.white70,
                                ),
                              ],
                            ],
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
      },
    );
  }

  Widget _buildNotFriendsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'You are not friends with ${widget.otherUsername}',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FriendsPage()));
            },
            child: const Text('Go to Friends Page'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FriendsPage()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_areFriends)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.amber.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You need to be friends with ${widget.otherUsername} to start chatting',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const FriendsPage()));
                          },
                          child: const Text('Add Friend'),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildChatMessages()),
                if (_areFriends) _buildMessageComposer(),
              ],
            ),
    );
  }
}
