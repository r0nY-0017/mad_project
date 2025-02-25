import 'package:flutter/material.dart';
import 'donor_list.dart'; // Import the new Donor List page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeActivity(),
    );
  }
}

class HomeActivity extends StatefulWidget {
  @override
  MyState createState() => MyState();
}

class MyState extends State<HomeActivity> {
  SnackMessage(message, context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Blood Donation"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 225, 160, 156),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Donor List"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (value) {
          if (value == 0) {
            SnackMessage("Bottom Navigation Home Button is Pressed", context);
          } else if (value == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DonorListPage()),
            );
          } else {
            SnackMessage("Bottom Navigation Profile Button is Pressed", context);
          }
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("DrawerHeader1")),
            DrawerHeader(child: Text("DrawerHeader2")),
            DrawerHeader(child: Text("DrawerHeader3")),
          ],
        ),
      ),
      body: Center(
        child: Text("Welcome to Blood Donation"),
      ),
    );
  }
}