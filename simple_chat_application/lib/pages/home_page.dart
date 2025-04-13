import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:simple_chat_application/pages/chat_page.dart';
import 'package:simple_chat_application/pages/group_chat_page.dart';
import 'package:simple_chat_application/pages/create_group_page.dart';
import 'package:simple_chat_application/services/user_status_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserStatusService _userStatusService = UserStatusService();

  @override
  void initState() {
    super.initState();
    _updateUserStatus(true);
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    super.dispose();
  }

  Future<void> _updateUserStatus(bool isOnline) async {
    if (_auth.currentUser != null) {
      await _userStatusService.updateUserStatus(isOnline);
    }
  }

  Future<void> _signOut() async {
    await _updateUserStatus(false);
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void _createNewGroup() {
      Navigator.push(
        context,
      MaterialPageRoute(builder: (context) => const CreateGroupPage()),
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .where('isGroup', isEqualTo: false)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing chat system...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we set up the database indexes. This may take a few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var chats = snapshot.data?.docs ?? [];
        if (chats.isEmpty) {
          return const Center(child: Text('No chats yet'));
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index].data() as Map<String, dynamic>;
            var participants = List<String>.from(chat['participants']);
            var otherUserId = participants.firstWhere(
              (id) => id != _auth.currentUser?.uid,
              orElse: () => '',
            );

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                var username = userData?['username'] ?? 'Unknown User';

                    return ListTile(
                      leading: CircleAvatar(
                    backgroundColor: Colors.green.shade700,
                        child: Text(
                      username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  title: Text(username),
                  subtitle: Text(chat['lastMessage'] ?? 'No messages yet'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                          chatId: chats[index].id,
                              otherUserId: otherUserId,
                          otherUsername: username,
                            ),
                          ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .where('isGroup', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing group chat system...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we set up the database indexes. This may take a few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var groups = snapshot.data?.docs ?? [];

        return Stack(
          children: [
            groups.isEmpty
                ? const Center(child: Text('No group chats yet'))
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      var group = groups[index].data() as Map<String, dynamic>;
                      var groupName = group['groupName'] ?? 'Unnamed Group';
                      var lastMessage = group['lastMessage'] ?? 'No messages yet';
                      var participantsCount = (group['participants'] as List).length;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: Text(
                            groupName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(groupName),
                        subtitle: Text('$lastMessage • $participantsCount members'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatPage(
                                chatId: groups[index].id,
                                groupName: groupName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _createNewGroup,
                backgroundColor: Colors.green.shade700,
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Chats' : 'Group Chats'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            color: Colors.white,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildChatsTab(),
          _buildGroupChatsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}