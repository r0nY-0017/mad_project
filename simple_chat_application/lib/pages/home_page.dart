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
    if (currentUserId == null) return;

    var chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    String? chatId;
    for (var doc in chatQuery.docs) {
      if ((doc['participants'] as List).contains(otherUserId)) {
        chatId = doc.id;
        break;
      }
    }

    if (chatId == null) {
      var newChat = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chatId: chatId!, otherUserId: otherUserId, otherUsername: otherUsername),
      ),
    );
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
            height: 100, // Increased slightly to accommodate content
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
                print('Found ${users.length} other users: ${users.map((u) => u['username']).toList()}');

                if (users.isEmpty) {
                  return const Center(child: Text("No other users registered yet"));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var userId = user.id;
                    var username = user['username'] as String? ?? 'Unknown';
                    var avatarUrl = user['avatarUrl'] as String? ?? 'https://robohash.org/John';

                    print('Displaying user: $username with avatar: $avatarUrl');

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _startChat(userId, username),
                            child: CircleAvatar(
                              radius: 25, // Reduced from 30 to fit within height
                              backgroundColor: Colors.grey.shade300,
                              child: ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Failed to load avatar for $username: $error');
                                    return const Icon(Icons.error, color: Colors.red, size: 25);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) =>
                                      loadingProgress == null ? child : const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            width: 60,
                            child: Text(
                              username,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey[400],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildChatList() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Center(child: Text("Please log in to view chats"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading chats"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No chats yet. Start a new one!"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chat = snapshot.data!.docs[index];
            var otherUserId = (chat['participants'] as List).firstWhere((id) => id != currentUserId);
            var lastMessage = chat['lastMessage'] ?? '';
            var lastMessageTime = chat['lastMessageTime'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const ListTile(title: Text("Loading..."));
                if (userSnapshot.hasError) return const ListTile(title: Text("Error loading user"));

                var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                var username = userData?['username'] ?? 'Unknown';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade200,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(username),
                  subtitle: Text(
                    lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    lastMessageTime != null ? DateFormat('hh:mm a').format(lastMessageTime.toDate()) : '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(chatId: chat.id, otherUserId: otherUserId, otherUsername: username),
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
}