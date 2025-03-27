import 'package:simple_chat_application/pages/home_page.dart';
import 'package:simple_chat_application/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/components/mytextField.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart'; // For email validation

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Function to show error or success messages
  void showMessage(String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}

  // Function to validate and login user using Firestore
  Future<void> validateAndLogin() async {
    String emailOrUsername = emailController.text.trim();
    String password = passwordController.text.trim();

    // Check for empty fields
    if (emailOrUsername.isEmpty || password.isEmpty) {
      showMessage('All fields are required!');
      return;
    }

    try {
      // Check if the input is an email or username
      QuerySnapshot userQuery;
      if (EmailValidator.validate(emailOrUsername)) {
        // Input is an email
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: emailOrUsername)
            .get();
      } else {
        // Input is a username
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .get();
      }

      // Check if user exists
      if (userQuery.docs.isEmpty) {
        showMessage('User not found!');
        return;
      }

      // Get the user document
      var userDoc = userQuery.docs.first;
      String storedPassword = userDoc['password'] as String;

      // Validate password
      if (storedPassword != password) {
        showMessage('Incorrect password!');
        return;
      }

      // If credentials are valid, show success message and navigate to HomePage
      showMessage('Login successful!', isError: false);

      // Navigate to HomePage after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      // Handle any errors during Firestore query
      showMessage('Login failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with wave effect
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: CustomPaint(
              painter: WavePainter(),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 150,
                    height: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 120),
                  Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MyTextfield(
                    obscureText: false,
                    label: "Email/Username",
                    controller: emailController,
                  ),
                  const SizedBox(height: 20),
                  MyTextfield(
                    obscureText: true,
                    label: "Password",
                    controller: passwordController,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ElevatedButton(
                      onPressed: validateAndLogin, // Call the validation and login function
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// Custom Painter for Wave Effect
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade900
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    
    // Create wave effect
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    // Draw bottom color
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6),
      Paint()..color = Colors.white,
    );
    
    // Draw wave
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}