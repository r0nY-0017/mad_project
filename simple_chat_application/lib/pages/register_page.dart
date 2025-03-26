import 'package:simple_chat_application/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/components/myTextField.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController email_Controller = TextEditingController();
  final TextEditingController uname_Controller = TextEditingController();
  final TextEditingController pw_Controller = TextEditingController();
  final TextEditingController cpw_Controller = TextEditingController();

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
              "Register",
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            MyTextfield(
              obscureText: false,
              label: "Email",
              controller: email_Controller, // Attach email controller
            ),

            const SizedBox(height: 20),
            MyTextfield(
              obscureText: false,
              label: "Username",
              controller: uname_Controller, // Attach email controller
            ),

            const SizedBox(height: 20),
            MyTextfield(
              obscureText: true,
              label: "Password",
              controller: pw_Controller, // Attach password controller
            ),

              // Password Field
            const SizedBox(height: 20),
            MyTextfield(
              obscureText: true,
              label: "Confirm Password",
              controller: cpw_Controller, // Attach password controller
            ),

            //Button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // Makes the button take full width
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60), // Adjust padding
                child: ElevatedButton(
                  onPressed: () {
                    print("Register Button Clicked");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 17), // Adjust height
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
                    fontSize: 12,
                  ),
                ),
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage()
                      ),
                    );
                  },
                  child: Text(
                    "Login",
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