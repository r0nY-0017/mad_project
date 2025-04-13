import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:simple_chat_application/components/myTextField.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController unameController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController cpwController = TextEditingController();

  // List of predefined avatar URLs using RoboHash
  final List<Map<String, String>> avatars = [
    {'gender': 'John', 'url': 'https://robohash.org/John'},
    {'gender': 'Alex', 'url': 'https://robohash.org/Alex'},
    {'gender': 'Peter', 'url': 'https://robohash.org/Peter'},
    {'gender': 'Jane', 'url': 'https://robohash.org/Jane'},
    {'gender': 'Emma', 'url': 'https://robohash.org/Emma'},
    {'gender': 'Sophia', 'url': 'https://robohash.org/Sophia'},
  ];

  // Selected avatar URL (default to the first male avatar)
  String? selectedAvatarUrl = 'https://robohash.org/John';

  // Function to show error or success messages
  void showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message, style: const TextStyle(color: Colors.white))),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Function to validate password strength
  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  // Function to check if email or username already exists in Firestore
  Future<bool> checkIfUserExists(String email, String username) async {
    try {
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return emailQuery.docs.isNotEmpty || usernameQuery.docs.isNotEmpty;
    } catch (e) {
      //showMessage('Error checking user: $e');
      return false;
    }
  }

  // Function to add user to Firebase (Auth + Firestore)
  Future<void> addUsers(String name, String email, String username, String password) async {
    try {
      // Step 1: Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      showMessage('Authentication successful', isError: false);

      // Step 2: Use default avatar if none selected
      String avatarUrl = selectedAvatarUrl ?? avatars[0]['url']!;

      // Step 3: Add user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'username': username,
        'avatarUrl': avatarUrl,
        'createdAt': Timestamp.now(),
        'friends': [],           // Add empty friends array
        'friendRequests': [],    // Add empty friend requests array
        'status': 'Hey there! I am using Adda Chat', // Default status
      });
      showMessage('Firestore data saved successfully', isError: false);

      // Step 4: Navigate to LoginPage
      showMessage('Registered Successfully', isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      showMessage('Failed to Register: ${e.toString()}');
    }
  }

  // Validation and registration logic
  void validateAndRegister() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String username = unameController.text.trim();
    String password = pwController.text.trim();
    String confirmPassword = cpwController.text.trim();

    if (name.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('All fields are required!');
      return;
    }

    if (!EmailValidator.validate(email)) {
      showMessage('Please enter a valid email address!');
      return;
    }

    bool userExists = await checkIfUserExists(email, username);
    if (userExists) {
      showMessage('Email or username already exists!');
      return;
    }

    if (password.length < 8) {
      showMessage('Password must be at least 8 characters long!');
      return;
    }
    if (!isPasswordStrong(password)) {
      showMessage('Password must contain at least one uppercase letter, one digit, and one special character!');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match!');
      return;
    }

    await addUsers(name, email, username, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 150,
                height: 150,
                color: Colors.green.shade900,
              ),
              Text(
                "Register",
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Select an Avatar", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    String avatarUrl = avatars[index]['url']!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatarUrl = avatarUrl;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: selectedAvatarUrl == avatarUrl
                                    ? Border.all(color: Colors.green.shade700, width: 2)
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade300,
                                child: ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error, color: Colors.red, size: 30),
                                    loadingBuilder: (context, child, loadingProgress) =>
                                        loadingProgress == null ? child : const CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              avatars[index]['gender']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedAvatarUrl == avatarUrl ? Colors.green.shade700 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              MyTextfield(obscureText: false, label: "Full Name", controller: nameController),
              const SizedBox(height: 20),
              MyTextfield(obscureText: false, label: "Email", controller: emailController),
              const SizedBox(height: 20),
              MyTextfield(obscureText: false, label: "Username", controller: unameController),
              const SizedBox(height: 20),
              MyTextfield(obscureText: true, label: "Password", controller: pwController),
              const SizedBox(height: 20),
              MyTextfield(obscureText: true, label: "Confirm Password", controller: cpwController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ElevatedButton(
                    onPressed: validateAndRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?  ", style: TextStyle(color: Colors.green.shade900, fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    unameController.dispose();
    pwController.dispose();
    cpwController.dispose();
    super.dispose();
  }
}