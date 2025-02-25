import 'package:flutter/material.dart';

class DonorListPage extends StatelessWidget {
  final List<String> donorNames = [
    "Md. Rahim",
    "Ayesha Akter",
    "Md. Karim",
    "Fatema Begum",
    "Md. Hasan",
    "Rokeya Sultana",
    "Md. Alamgir",
    "Shirin Akter",
    "Md. Shakil",
    "Nusrat Jahan"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donor List"),
        backgroundColor: const Color.fromARGB(255, 225, 160, 156),
      ),
      body: ListView.builder(
        itemCount: donorNames.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(donorNames[index]),
              trailing: ElevatedButton(
                onPressed: () {
                  // Navigate to donor details page
                },
                child: Text("Details"),
              ),
            ),
          );
        },
      ),
    );
  }
}