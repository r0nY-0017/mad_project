import 'package:flutter/material.dart';

class DonorDetailsPage extends StatelessWidget {
  final Map<String, String> donor;

  DonorDetailsPage({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donor Details"),
        backgroundColor: const Color.fromARGB(255, 225, 160, 156),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 200,
                color: Colors.grey,
              ),
              SizedBox(height: 16.0),
              Text("Name: ${donor["name"]}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.0),
              Text("Blood Group: ${donor["bloodGroup"]}", style: TextStyle(fontSize: 16, color: Colors.redAccent)),
              SizedBox(height: 8.0),
              Text("Address: ${donor["address"]}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8.0),
              Text("Mobile: ${donor["mobile"]}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8.0),
              Text("Age: ${donor["age"]}", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}