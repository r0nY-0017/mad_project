import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update user's online status
  Future<void> updateUserStatus(bool isOnline) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
    }
  }

  // Stream to listen to a user's online status
  Stream<bool> getUserStatusStream(String userId) {
    if (userId.isEmpty) return Stream.value(false);
    
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return false;
          final data = doc.data();
          if (data == null) return false;
          return data['isOnline'] ?? false;
        });
  }

  // Get user's last seen timestamp
  Stream<DateTime?> getUserLastSeenStream(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          final timestamp = data['lastSeen'] as Timestamp?;
          return timestamp?.toDate();
        });
  }
} 