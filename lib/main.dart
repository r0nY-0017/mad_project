import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:simple_chat_application/pages/home_page.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:simple_chat_application/services/setting_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      
      builder: (context, settings, child) {
        ThemeMode themeMode;
        switch (settings.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Adda Chat',
          theme: ThemeData(
            primarySwatch: Colors.green,
            brightness: Brightness.light,
            textTheme: _buildTextTheme(settings.fontSize),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.green,
            brightness: Brightness.dark,
            textTheme: _buildTextTheme(settings.fontSize),
          ),
          themeMode: themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return snapshot.hasData ? const HomePage() : const LoginPage();
            },
          ),
        );
      },
    );
  }

  TextTheme _buildTextTheme(String fontSize) {
    double baseFontSize;
    switch (fontSize) {
      case 'small':
        baseFontSize = 10.0;
        break;
      case 'large':
        baseFontSize = 18.0;
        break;
      case 'medium':
      default:
        baseFontSize = 14.0;
    }

    return TextTheme(
      bodyMedium: TextStyle(fontSize: baseFontSize),
      bodyLarge: TextStyle(fontSize: baseFontSize + 2),
      titleMedium: TextStyle(fontSize: baseFontSize + 4),
      titleLarge: TextStyle(fontSize: baseFontSize + 8),
    );
  }
}