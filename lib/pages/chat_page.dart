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
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final UserStatusService _userStatusService = UserStatusService();
  bool _isLoading = true;
  bool _areFriends = false;

  @override
  void initState() {
    super.initState();
    _checkFriendshipStatus();
    _markMessagesAsSeen();
    _userStatusService.updateUserStatus(true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _userStatusService.updateUserStatus(false);
    super.dispose();
  }

  Future<void> _checkFriendshipStatus() async {
    print('ChatPage: Starting friendship status check');
    print('Current user ID: ${_auth.currentUser?.uid}');
    print('Other user ID: ${widget.otherUserId}');
    
    try {
      // Try to get both user documents to debug
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
          
      print('Current user document exists: ${currentUserDoc.exists}');
      print('Current user data: ${currentUserDoc.data()}');
      print('Other user document exists: ${otherUserDoc.exists}');
      print('Other user data: ${otherUserDoc.data()}');
      
      final friendsService = FriendsService();
      final areFriends = await friendsService.areFriends(widget.otherUserId);
      print('ChatPage: Friendship check result: $areFriends');
      setState(() {
        _areFriends = areFriends;
        _isLoading = false;
      });
      print('ChatPage: Updated state - areFriends: $_areFriends');
    } catch (e) {
      print('Error in _checkFriendshipStatus: $e');
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
      var messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      for (var doc in messages.docs) {
        var data = doc.data();
        var seenBy = List<String>.from(data['seenBy'] ?? []);
        if (!seenBy.contains(currentUserId)) {
          await doc.reference.update({
            'seenBy': FieldValue.arrayUnion([currentUserId]),
          });
        }
      }
      print('Marked ${messages.docs.length} messages as seen for user: $currentUserId');
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      var messageText = _messageController.text.trim();
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

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('Sent message: "$messageText" in chat ${widget.chatId}');
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
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUsername,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            StreamBuilder<bool>(
              stream: _userStatusService.getUserStatusStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return const Text(
                    'Online',
                    style: TextStyle(fontSize: 12),
                  );
                } else {
                  return StreamBuilder<DateTime?>(
                    stream: _userStatusService.getUserLastSeenStream(widget.otherUserId),
                    builder: (context, lastSeenSnapshot) {
                      if (lastSeenSnapshot.hasData && lastSeenSnapshot.data != null) {
                        return Text(
                          'Last seen ${DateFormat('hh:mm a').format(lastSeenSnapshot.data!)}',
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const Text(
                        'Offline',
                        style: TextStyle(fontSize: 12),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsPage(),
                ),
              );
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
                    padding: const EdgeInsets.all(16.0),
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
                                builder: (context) => const FriendsPage(),
                              ),
                            );
                          },
                          child: const Text('Add Friend'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('Something went wrong'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!_areFriends) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'You are not friends with ${widget.otherUsername}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FriendsPage(),
                                    ),
                                  );
                                },
                                child: const Text('Go to Friends Page'),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;
                      
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet. Start chatting!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          var isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
                          var seenBy = List<String>.from(message['seenBy'] ?? []);
                          var isSeen = seenBy.contains(widget.otherUserId);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Row(
                              mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? Colors.green.shade700 : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['text'] ?? '',
                                          style: TextStyle(
                                            color: isCurrentUser ? Colors.white : Colors.black,
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
                                                      (message['timestamp'] as Timestamp).toDate())
                                                  : '',
                                              style: TextStyle(
                                                color: isCurrentUser ? Colors.white70 : Colors.grey.shade600,
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
                  ),
                ),
                if (_areFriends)
                  Padding(
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
                  ),
              ],
            ),
    );
  }
}