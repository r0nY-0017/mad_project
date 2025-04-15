import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_chat_application/services/setting_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _clearChats(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chats'),
        content: const Text('Are you sure you want to delete all your chats? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final chats = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();

        for (var chat in chats.docs) {
          final messages = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chat.id)
              .collection('messages')
              .get();
          for (var msg in messages.docs) {
            batch.delete(msg.reference);
          }
          batch.delete(chat.reference);
        }

        await batch.commit();
        print('SettingsPage: Cleared all chats');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All chats deleted'), backgroundColor: Colors.green),
        );
      } catch (e) {
        print('SettingsPage: Error clearing chats: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing chats: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Appearance'),
              subtitle: const Text('Customize theme and look'),
              leading: const Icon(Icons.brightness_6, color: Colors.green),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Theme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: const Text('Light'),
                          value: 'light',
                          groupValue: settings.themeMode,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            settings.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dark'),
                          value: 'dark',
                          groupValue: settings.themeMode,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            settings.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('System'),
                          value: 'system',
                          groupValue: settings.themeMode,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            settings.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Chat Settings'),
              subtitle: const Text('Message font size and more'),
              children: [
                ListTile(
                  title: const Text('Message Font Size'),
                  subtitle: Text('Current: ${settings.fontSize}'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Font Size'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text('Small'),
                              value: 'small',
                              groupValue: settings.fontSize,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                settings.setFontSize(value!);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Medium'),
                              value: 'medium',
                              groupValue: settings.fontSize,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                settings.setFontSize(value!);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Large'),
                              value: 'large',
                              groupValue: settings.fontSize,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                settings.setFontSize(value!);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable or disable notifications'),
                  value: settings.notificationsEnabled,
                  activeColor: Colors.green,
                  onChanged: (enabled) {
                    settings.setNotificationsEnabled(enabled);
                  },
                ),
                ListTile(
                  title: const Text('Clear Chats'),
                  subtitle: const Text('Delete all chat history'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _clearChats(context),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('About'),
              subtitle: const Text('App version and info'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About Adda Chat'),
                    content: const Text('Adda Chat v1.0.0\nA simple and secure chat application.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}