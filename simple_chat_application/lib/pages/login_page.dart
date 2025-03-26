import 'package:simple_chat_application/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/components/mytextField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 70,
              color: Colors.green.shade700,
            ),
            Text(
              "Welcome to Chat App",
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),

            // Email Field
            MyTextfield(
              obscureText: false,
              label: "Email/Username",
              controller: emailController, // Attach email controller
            ),
            const SizedBox(height: 20),

            // Password Field
            MyTextfield(
              obscureText: true,
              label: "Password",
              controller: passwordController, // Attach password controller
            ),

            //Button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // Makes the button take full width
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60), // Adjust padding
                child: ElevatedButton(
                  onPressed: () {
                    print("Login Button Clicked");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 17), // Adjust height
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
            ),
            
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?  ",
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontSize: 12,
                  ),
                ),
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterPage()
                      ),
                    );
                  },
                  child: Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
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
    );
  }
}