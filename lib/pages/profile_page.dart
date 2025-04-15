import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _statusController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  // Helper Method: Handle Status Update
  Future<void> _updateStatus(String currentStatus) async {
    setState(() => _isEditing = true);
    _statusController.text = currentStatus;

    final result = await _showStatusDialog();
    if (result != null) {
      try {
        await _updateUserProfile({'status': result});
        _showSnackbar('Status updated successfully');
      } catch (e) {
        _showSnackbar('Error updating status: $e');
      }
    }
    setState(() => _isEditing = false);
  }

  // Helper Method: Show Status Dialog
  Future<String?> _showStatusDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: TextField(
          controller: _statusController,
          decoration: const InputDecoration(
            hintText: 'Enter your status...',
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _statusController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Helper Method: Update User Profile
  Future<void> _updateUserProfile(Map<String, dynamic> updates) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .update(updates);
  }

  // Helper Method: Show SnackBar
  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Helper Method: Handle Avatar Update
  Future<void> _updateAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final File imageFile = File(image.path);
      final String fileName =
          '${_auth.currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload Image to Firebase Storage
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('avatars/$fileName');
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      await _showUploadProgress(uploadTask);

      final downloadUrl = await storageRef.getDownloadURL();
      await _updateUserProfile({'avatarUrl': downloadUrl});
      _showSnackbar('Profile picture updated successfully');
    } catch (e) {
      _showSnackbar('Error updating profile picture: $e');
    }
  }

  // Helper Method: Show Upload Progress
  Future<void> _showUploadProgress(UploadTask uploadTask) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<TaskSnapshot>(
        stream: uploadTask.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final progress =
                snapshot.data!.bytesTransferred / snapshot.data!.totalBytes;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Uploading: ${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            );
          }
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing upload...'),
              ],
            ),
          );
        },
      ),
    );
    await uploadTask;
    if (!mounted) return;
    Navigator.pop(context); // Close progress dialog
  }

  // UI: Build Profile Page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Unknown User';
          final email = userData['email'] ?? '';
          final status = userData['status'] ??
              'Hey there! I am using Adda Chat - The Best Chat App!';
          final avatarUrl = userData['avatarUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAvatarSection(avatarUrl),
                const SizedBox(height: 24),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusSection(status),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper Method: Avatar Section
  Widget _buildAvatarSection(String? avatarUrl) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 80)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: Colors.green.shade700,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _updateAvatar,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Method: Status Section
  Widget _buildStatusSection(String status) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: Colors.green),
      title: Text(
        status,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: const Text('About Me'),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.green),
        onPressed: () => _updateStatus(status),
      ),
    );
  }
}
