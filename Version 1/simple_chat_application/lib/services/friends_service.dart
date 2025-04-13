import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize user document with required fields
  Future<void> initializeUserDocument() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user ID available');
      return;
    }

    try {
      print('Attempting to initialize document for user: $currentUserId');
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      
      print('Document exists: ${userDoc.exists}');
      print('Document data: ${userDoc.data()}');
      
      if (!userDoc.exists || userDoc.data() == null) {
        print('Creating new user document...');
        final userData = {
          'friends': [],
          'friendRequests': [],
          'email': _auth.currentUser?.email,
          'username': _auth.currentUser?.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
        };
        print('Setting user data: $userData');
        await _firestore.collection('users').doc(currentUserId).set(userData);
        print('New document created successfully');
      } else {
        // Ensure required fields exist
        final data = userDoc.data()!;
        final updates = <String, dynamic>{};
        
        print('Checking for missing fields in existing document');
        if (!data.containsKey('friends')) {
          print('Adding missing friends field');
          updates['friends'] = [];
        }
        if (!data.containsKey('friendRequests')) {
          print('Adding missing friendRequests field');
          updates['friendRequests'] = [];
        }
        
        if (updates.isNotEmpty) {
          print('Updating document with missing fields: $updates');
          await _firestore.collection('users').doc(currentUserId).update(updates);
          print('Document updated successfully');
        } else {
          print('All required fields exist');
        }
      }

      // Verify the document after initialization
      final verifyDoc = await _firestore.collection('users').doc(currentUserId).get();
      print('Verification - Document exists: ${verifyDoc.exists}');
      print('Verification - Document data: ${verifyDoc.data()}');
    } catch (e) {
      print('Error initializing user document: $e');
      print('Error stack trace: ${e is Error ? e.stackTrace : 'No stack trace'}');
      throw e;
    }
  }

  // Send friend request by updating the receiver's user document
  Future<void> sendFriendRequest(String receiverId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    print('Attempting to send friend request from $currentUserId to $receiverId');

    try {
      // Initialize current user's document
      await initializeUserDocument();

      // Check if receiver exists and initialize their document
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      
      if (!receiverDoc.exists) {
        print('Receiver document does not exist');
        throw 'User not found';
      }

      // Initialize receiver's document if needed
      if (receiverDoc.data() == null || !receiverDoc.data()!.containsKey('friends')) {
        await _firestore.collection('users').doc(receiverId).set({
          'friends': [],
          'friendRequests': [],
        }, SetOptions(merge: true));
      }

      // Get updated receiver document
      final updatedReceiverDoc = await _firestore.collection('users').doc(receiverId).get();
      print('Receiver document data: ${updatedReceiverDoc.data()}');

      final receiverFriends = List<String>.from(updatedReceiverDoc.data()?['friends'] ?? []);
      if (receiverFriends.contains(currentUserId)) {
        print('Already friends');
        throw 'Already friends with this user';
      }

      // Check if request already exists
      final receiverRequests = List<Map<String, dynamic>>.from(
          updatedReceiverDoc.data()?['friendRequests'] ?? []);
      print('Current friend requests: $receiverRequests');
      
      bool requestExists = receiverRequests.any((request) =>
          request['senderId'] == currentUserId && request['status'] == 'pending');
      if (requestExists) {
        print('Request already exists');
        throw 'Friend request already sent';
      }

      // Add friend request with current timestamp
      print('Sending friend request...');
      await _firestore.collection('users').doc(receiverId).update({
        'friendRequests': FieldValue.arrayUnion([
          {
            'senderId': currentUserId,
            'status': 'pending',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        ])
      });
      print('Friend request sent successfully');
    } catch (e) {
      print('Error sending friend request: $e');
      throw e;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Get the current user's document to find the request with timestamp
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final friendRequests = List<Map<String, dynamic>>.from(currentUserDoc.data()?['friendRequests'] ?? []);
      final request = friendRequests.firstWhere(
        (req) => req['senderId'] == senderId && req['status'] == 'pending',
        orElse: () => {},
      );

      // Start a batch write
      final batch = _firestore.batch();

      // Update current user's document
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([senderId]),
        'friendRequests': FieldValue.arrayRemove([request])
      });

      // Update sender's document
      final senderRef = _firestore.collection('users').doc(senderId);
      batch.update(senderRef, {
        'friends': FieldValue.arrayUnion([currentUserId])
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error accepting friend request: $e');
      throw e;
    }
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([
        {
          'senderId': senderId,
          'status': 'pending',
        }
      ])
    });
  }

  // Check if users are friends
  Future<bool> areFriends(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    print('Checking friendship status between $currentUserId and $otherUserId');

    try {
      // Initialize user document if needed
      await initializeUserDocument();
      
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      print('Current user document data: ${userDoc.data()}');
      
      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
      final isFriend = friends.contains(otherUserId);
      
      print('Friends list: $friends');
      print('Is friend? $isFriend');
      
      return isFriend;
    } catch (e) {
      print('Error checking friendship status: $e');
      return false;
    }
  }

  // Get friend requests
  Stream<List<Map<String, dynamic>>> getFriendRequests() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      final requests = doc.data()?['friendRequests'] ?? [];
      return List<Map<String, dynamic>>.from(requests);
    });
  }

  // Get friends list
  Stream<List<String>> getFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      final friends = doc.data()?['friends'] ?? [];
      return List<String>.from(friends);
    });
  }
} 