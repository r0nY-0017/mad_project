import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_chat_application/services/friends_service.dart';
import 'package:simple_chat_application/pages/chat_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to display the Add Friend dialog
  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Find Friends'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search TextField
              _buildSearchTextField(),

              const SizedBox(height: 16),
              const Text(
                'People you might know:',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              // Stream to display search results
              _buildSearchResults(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Method to build the search TextField widget
  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by username',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      onChanged: (value) {
        setState(() {}); // Trigger rebuild to update search results
      },
    );
  }

  // StreamBuilder to show search results
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchController.text)
          .where('username', isLessThan: _searchController.text + 'z')
          .limit(10) // Limit results for better performance
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = _auth.currentUser?.uid;
        final users = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .toList();

        if (users.isEmpty) {
          return _buildNoResultsFound();
        }

        return _buildUserList(users);
      },
    );
  }

  // Method to show 'No results found' when no users are available
  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Start typing to search for users'
                : 'No users found',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Method to build the user list from search results
  Widget _buildUserList(List<DocumentSnapshot> users) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final userData = users[index].data() as Map<String, dynamic>;
          final userId = users[index].id;
          final username = userData['username'] ?? 'Unknown User';
          final avatarUrl = userData['avatarUrl'];

          return _buildFriendTile(userId, username, avatarUrl);
        },
      ),
    );
  }

  // Method to build the Friend Tile
  Widget _buildFriendTile(String userId, String username, String? avatarUrl) {
    return FutureBuilder<bool>(
      future: _friendsService.areFriends(userId),
      builder: (context, friendSnapshot) {
        final areFriends = friendSnapshot.data ?? false;
        final hasPendingRequest =
            false; // TODO: Implement pending request check

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(username),
          subtitle: Text(
            areFriends
                ? 'Already friends'
                : hasPendingRequest
                    ? 'Request pending'
                    : 'Tap to send friend request',
            style: TextStyle(
              color: areFriends
                  ? Colors.green
                  : hasPendingRequest
                      ? Colors.orange
                      : Colors.grey,
            ),
          ),
          trailing: _buildFriendRequestIconButton(
              userId, username, areFriends, hasPendingRequest),
        );
      },
    );
  }

  // Method to build the button for sending a friend request or displaying request status
  Widget _buildFriendRequestIconButton(
      String userId, String username, bool areFriends, bool hasPendingRequest) {
    return IconButton(
      icon: Icon(
        areFriends
            ? Icons.check_circle
            : hasPendingRequest
                ? Icons.pending
                : Icons.person_add,
        color: areFriends
            ? Colors.green
            : hasPendingRequest
                ? Colors.orange
                : Colors.grey,
      ),
      onPressed: areFriends || hasPendingRequest
          ? null
          : () async {
              await _sendFriendRequest(userId, username);
            },
    );
  }

  // Method to send a friend request
  Future<void> _sendFriendRequest(String userId, String username) async {
    try {
      await _friendsService.sendFriendRequest(userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $username'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to start a chat with a friend
  Future<void> _startChat(String otherUserId, String otherUsername) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Check if users are friends
    final areFriends = await _friendsService.areFriends(otherUserId);
    if (!areFriends) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only chat with friends')),
        );
      }
      return;
    }

    // Find or create chat
    var chatQuery = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    String? chatId;
    for (var doc in chatQuery.docs) {
      var participants = doc['participants'] as List;
      if (participants.contains(otherUserId)) {
        chatId = doc.id;
        break;
      }
    }

    if (chatId == null) {
      var chatData = {
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      };
      var newChat = await _firestore.collection('chats').add(chatData);
      chatId = newChat.id;
    }

    if (mounted) {
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
    }
  }

  // Build the main FriendsPage UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.green.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildFriendRequestsList(),
        ],
      ),
    );
  }

  // Widget to show the list of friends
  Widget _buildFriendsList() {
    return StreamBuilder<List<String>>(
      stream: _friendsService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data!;
        if (friends.isEmpty) {
          return const Center(child: Text('No friends yet'));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendId = friends[index];

            return _buildFriendTileFromId(friendId);
          },
        );
      },
    );
  }

  // Helper method to build the friend list tile
  Widget _buildFriendTileFromId(String friendId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(friendId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Unknown User';
        final avatarUrl = userData['avatarUrl'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(username),
          subtitle: Text(userData['status'] ?? ''),
          onTap: () => _startChat(friendId, username),
        );
      },
    );
  }

  // Widget to show the list of friend requests
  Widget _buildFriendRequestsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendsService.getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('No pending friend requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'] as String;

            return _buildRequestTile(senderId);
          },
        );
      },
    );
  }

  // Helper method to build a friend request tile
  Widget _buildRequestTile(String senderId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(senderId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Unknown User';
        final avatarUrl = userData['avatarUrl'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(username),
          subtitle: const Text('Wants to be your friend'),
          trailing: _buildRequestActions(senderId),
        );
      },
    );
  }

  // Method to build accept/reject buttons for friend requests
  Widget _buildRequestActions(String senderId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () async {
            try {
              await _friendsService.acceptFriendRequest(senderId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request accepted')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () async {
            try {
              await _friendsService.rejectFriendRequest(senderId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request rejected')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
