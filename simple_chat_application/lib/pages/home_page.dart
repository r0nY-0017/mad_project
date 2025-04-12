import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:simple_chat_application/pages/chat_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon!')),
        );
        break;
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Future<void> _startChat(String otherUserId, String otherUsername) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('Error: No current user logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a chat'), backgroundColor: Colors.red),
      );
      return;
    }

    print('Starting chat with user: $otherUsername ($otherUserId)');

    try {
      print('Querying chats for user: $currentUserId');
      var chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? chatId;
      print('Found ${chatQuery.docs.length} chats');
      for (var doc in chatQuery.docs) {
        var participants = doc['participants'] as List;
        print('Checking chat ${doc.id} with participants: $participants');
        if (participants.contains(otherUserId)) {
          chatId = doc.id;
          print('Found existing chat: $chatId');
          break;
        }
      }

      if (chatId == null) {
        print('No existing chat found. Creating new chat for $currentUserId and $otherUserId');
        var chatData = {
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        };
        print('Chat data to be sent: $chatData');
        var newChat = await FirebaseFirestore.instance.collection('chats').add(chatData);
        chatId = newChat.id;
        print('Created new chat: $chatId');
        var createdChat = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
        print('Verified chat $chatId: ${createdChat.data()}');
      }

      print('Navigating to ChatPage with chatId: $chatId, otherUser: $otherUsername');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: chatId!,
            otherUserId: otherUserId,
            otherUsername: otherUsername,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Adda Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search feature coming soon!')));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.hasError) {
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.green.shade700),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>?;
                String avatarUrl = userData?['avatarUrl'] ?? 'https://robohash.org/John';
                String fullName = userData?['name'] ?? 'User';
                String email = userData?['email'] ?? 'No email';

                return DrawerHeader(
                  decoration: BoxDecoration(color: Colors.green.shade700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red, size: 30),
                            loadingBuilder: (context, child, loadingProgress) =>
                                loadingProgress == null ? child : const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.group), title: const Text("Groups"), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("No", style: TextStyle(color: Colors.grey))),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _signOut();
                        },
                        child: const Text("Yes", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error loading users: ${snapshot.error}');
                  return const Center(child: Text("Error loading users"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No users found in Firestore');
                  return const Center(child: Text("No users found"));
                }

                var users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();
                print('Found ${users.length} other users: ${users.map((u) => u['name']).toList()}');

                if (users.isEmpty) {
                  return const Center(child: Text("No other users registered yet"));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var userId = user.id;
                    var fullName = user['name'] as String? ?? 'Unknown';
                    var avatarUrl = user['avatarUrl'] as String? ?? 'https://robohash.org/John';

                    print('Displaying user: $fullName with avatar: $avatarUrl');

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          print('Tapped user: $fullName ($userId)');
                          _startChat(userId, fullName);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey.shade300,
                              child: ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Failed to load avatar for $fullName: $error');
                                    return const Icon(Icons.error, color: Colors.red, size: 25);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) =>
                                      loadingProgress == null ? child : const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 60,
                              child: Text(
                                fullName,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _selectedIndex == 0 ? _buildChatList() : const Center(child: Text("Feature coming soon!")),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New chat feature coming soon!')));
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.message, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey[400],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildChatList() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No user logged in');
      return const Center(child: Text("Please log in to view chats"));
    }

    print('Building conversation list for user: $currentUserId');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error loading conversations: ${snapshot.error}');
          return const Center(child: Text("Error loading conversations"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Waiting for conversations to load');
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No conversations found for user: $currentUserId');
          return const Center(child: Text("No Message"));
        }

        var chats = snapshot.data!.docs;
        print('Found ${chats.length} conversations for user: $currentUserId');
        for (var chat in chats) {
          print('Conversation ${chat.id}: ${chat.data()}');
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            var chatData = chat.data() as Map<String, dynamic>;
            var participants = chatData['participants'] as List<dynamic>? ?? [];
            var otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => null,
            );

            if (otherUserId == null) {
              print('No other user found for conversation ${chat.id}');
              return const SizedBox.shrink();
            }

            var lastMessage = chatData['lastMessage'] as String? ?? '';
            var lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  print('Error loading user $otherUserId: ${userSnapshot.error}');
                  return const ListTile(title: Text("Error loading user"));
                }
                if (!userSnapshot.hasData) {
                  print('Loading user $otherUserId');
                  return const ListTile(title: Text("Loading..."));
                }

                var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                var fullName = userData?['name'] as String? ?? 'Unknown';
                print('Fetched user: $fullName ($otherUserId) for conversation ${chat.id}');

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chat.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    bool isUnseen = false;
                    String displayMessage = lastMessage;
                    String displayTime = '';

                    if (messageSnapshot.hasError) {
                      print('Error loading messages for conversation ${chat.id}: ${messageSnapshot.error}');
                    }
                    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                      var lastMessageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      var seenBy = lastMessageData['seenBy'] as List<dynamic>? ?? [];
                      isUnseen = lastMessageData['senderId'] != currentUserId && !seenBy.contains(currentUserId);
                      displayMessage = lastMessageData['text'] as String? ?? 'No messages yet';
                      var messageTime = lastMessageData['timestamp'] as Timestamp?;
                      displayTime = messageTime != null
                          ? DateFormat('hh:mm a').format(messageTime.toDate())
                          : (lastMessageTime != null
                              ? DateFormat('hh:mm a').format(lastMessageTime.toDate())
                              : '');
                      print('Conversation ${chat.id} last message: $lastMessageData, isUnseen: $isUnseen');
                    } else if (lastMessageTime != null) {
                      displayTime = DateFormat('hh:mm a').format(lastMessageTime.toDate());
                      print('No messages yet for conversation ${chat.id}, using chat lastMessageTime');
                    } else {
                      print('No messages or timestamp for conversation ${chat.id}');
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade200,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        fullName,
                        style: TextStyle(
                          fontWeight: isUnseen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        displayMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isUnseen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        displayTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: isUnseen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        print('Tapped conversation with $fullName ($otherUserId, chatId: ${chat.id})');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatId: chat.id,
                              otherUserId: otherUserId,
                              otherUsername: fullName,
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
      },
    );
  }
}