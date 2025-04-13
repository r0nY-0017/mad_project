import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;

  const MyTextfield({
    super.key,
    required this.label,
    required this.obscureText,
    required this.controller,
  });

  @override
  MyTextfieldState createState() => MyTextfieldState();
}

class MyTextfieldState extends State<MyTextfield> {
  late bool obscureText;
  Color iconColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    obscureText = widget.obscureText; // Initialize obscureText
  }

  void togglePasswordVisibility() {
    setState(() {
      obscureText = !obscureText;
      iconColor = obscureText ? Colors.grey : Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: TextField(
        controller: widget.controller, // Attach the controller
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade900),
            borderRadius: BorderRadius.circular(10.0),
          ),
          fillColor: Colors.white,
          filled: true,
          labelText: widget.label,
          
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
                  ),
                  onPressed: togglePasswordVisibility,
                )
              : null, // No icon for non-password fields
        ),
      ),
    );
  }
}