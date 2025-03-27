import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        print("Home tapped");
        break;
      case 1:
        print("Profile tapped");
        break;
      case 2:
        print("Settings tapped");
        break;
      default:
        print("Unknown tab tapped");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),

      drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.green),
                child: Center(
                  child: Text("End Drawer"),
                ),
              ),

              ListTile(
                leading: Icon(Icons.home),
                title: Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Settings"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Log Out"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

      body: const Center(
        child: Text("Welcome to Adda-Chat-App"),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items:[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Group',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.child_friendly_sharp),
            label: 'Friends',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[400],
        onTap: _onItemTapped,
      ),

    );

    
  }
}