import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:simple_chat_application/pages/chat_page.dart';
import 'package:simple_chat_application/pages/friends_page.dart';
import 'package:simple_chat_application/pages/profile_page.dart';
import 'package:simple_chat_application/pages/settings_page.dart';
import 'package:simple_chat_application/services/user_status_service.dart';
import 'package:simple_chat_application/services/friends_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserStatusService _userStatusService = UserStatusService();
  final FriendsService _friendsService = FriendsService();

  // List of pages to show in the bottom navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _pages = [
      ChatListPage(onStartChat: _startChat),
      const FriendsPage(),
      const SettingsPage(),
    ];
  }

  Future<void> _initializeUser() async {
    try {
      await _friendsService.initializeUserDocument();
      await _userStatusService.updateUserStatus(true);
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  @override
  void dispose() {
    _userStatusService.updateUserStatus(false);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Future<void> _clearAllChats() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Get all chats where the current user is a participant
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Add delete operations to batch
      for (var chatDoc in chatQuery.docs) {
        batch.delete(chatDoc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chats cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error clearing chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing chats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChat(String otherUserId, String otherUsername) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('Error: No current user logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in to start a chat'),
            backgroundColor: Colors.red),
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
        print(
            'No existing chat found. Creating new chat for $currentUserId and $otherUserId');
        var chatData = {
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        };
        print('Chat data to be sent: $chatData');
        var newChat =
            await FirebaseFirestore.instance.collection('chats').add(chatData);
        chatId = newChat.id;
        print('Created new chat: $chatId');
        var createdChat = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        print('Verified chat $chatId: ${createdChat.data()}');
      }

      print(
          'Navigating to ChatPage with chatId: $chatId, otherUser: $otherUsername');
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
      drawer: Drawer(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final username = userData['username'] ?? 'Unknown User';
            final email = userData['email'] ?? '';
            final avatarUrl = userData['avatarUrl'];

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                  ),
                  accountName: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Chats'),
                  selected: _selectedIndex == 0,
                  selectedColor: Colors.green.shade700,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Friends'),
                  selected: _selectedIndex == 1,
                  selectedColor: Colors.green.shade700,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  selected: _selectedIndex == 2,
                  selectedColor: Colors.green.shade700,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _signOut();
                  },
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: const Text("Adda Chat",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search feature coming soon!')));
            },
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final avatarUrl = userData['avatarUrl'];
                final status =
                    userData['status'] ?? 'Hey there! I am using Adda Chat';

                return Tooltip(
                  message: status,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.account_circle,
                                color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ChatListPage extends StatelessWidget {
  final Function(String, String) onStartChat;

  const ChatListPage({Key? key, required this.onStartChat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // Users list at the top
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs
                  .where((doc) => doc.id != currentUserId)
                  .toList();

              if (users.isEmpty) {
                return const Center(child: Text('No other users'));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userData = user.data() as Map<String, dynamic>;
                  final userId = user.id;
                  final username = userData['username'] ?? 'Unknown';
                  final profileImage = userData['avatarUrl'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () => onStartChat(userId, username),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage:
                                profileImage != null && profileImage.isNotEmpty
                                    ? NetworkImage(profileImage)
                                    : null,
                            child: profileImage == null || profileImage.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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

        // Chats list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final chats = snapshot.data!.docs;
              if (chats.isEmpty) {
                return const Center(child: Text('No chats yet'));
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final participants = chat['participants'] as List;
                  final otherUserId = participants.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => '',
                  );

                  if (otherUserId.isEmpty) return const SizedBox.shrink();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const ListTile(
                          leading: CircleAvatar(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final username = userData['username'] ?? 'Unknown User';
                      final profileImage = userData['avatarUrl'];
                      final lastMessage = chat['lastMessage'] ?? '';
                      final lastMessageTime =
                          chat['lastMessageTime'] as Timestamp?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              profileImage != null && profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(username),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: lastMessageTime != null
                            ? Text(
                                DateFormat.jm()
                                    .format(lastMessageTime.toDate()),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () => onStartChat(otherUserId, username),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
