import 'package:simple_chat_application/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/components/myTextField.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart'; // For email validation

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

  // Function to show error or success messages
  void showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Function to validate password strength
  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false; // At least one uppercase letter
    if (!password.contains(RegExp(r'[0-9]'))) return false; // At least one digit
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false; // At least one special character
    return true;
  }

  // Function to check if email or username already exists in Firestore
  Future<bool> checkIfUserExists(String email, String username) async {
    final emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    final usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return emailQuery.docs.isNotEmpty || usernameQuery.docs.isNotEmpty;
  }

  // Function to add user to Firebase (Authentication + Firestore)
  Future<void> addUsers(String name, String email, String username, String password) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'username': username,
        'createdAt': Timestamp.now(),
      });

      // Show success message
      showMessage('Registered Successfully', isError: false);

      // Navigate to LoginPage after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
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

    // Check for empty fields
    if (name.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('All fields are required!');
      return;
    }

    // Validate email
    if (!EmailValidator.validate(email)) {
      showMessage('Please enter a valid email address!');
      return;
    }

    // Check if email or username already exists
    bool userExists = await checkIfUserExists(email, username);
    if (userExists) {
      showMessage('Email or username already exists!');
      return;
    }

    // Validate password length and strength
    if (password.length < 8) {
      showMessage('Password must be at least 8 characters long!');
      return;
    }
    if (!isPasswordStrong(password)) {
      showMessage('Password must contain at least one uppercase letter, one digit, and one special character!');
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      showMessage('Passwords do not match!');
      return;
    }

    // If all validations pass, proceed to add user
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
              MyTextfield(
                obscureText: false,
                label: "Full Name",
                controller: nameController,
              ),
              const SizedBox(height: 20),
              MyTextfield(
                obscureText: false,
                label: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 20),
              MyTextfield(
                obscureText: false,
                label: "Username",
                controller: unameController,
              ),
              const SizedBox(height: 20),
              MyTextfield(
                obscureText: true,
                label: "Password",
                controller: pwController,
              ),
              const SizedBox(height: 20),
              MyTextfield(
                obscureText: true,
                label: "Confirm Password",
                controller: cpwController,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ElevatedButton(
                    onPressed: validateAndRegister, // Call the validation function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?  ",
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
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
    // Dispose controllers to free up resources
    nameController.dispose();
    emailController.dispose();
    unameController.dispose();
    pwController.dispose();
    cpwController.dispose();
    super.dispose();
  }
}