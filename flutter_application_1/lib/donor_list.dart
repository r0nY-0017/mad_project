import 'package:flutter/material.dart';
import './details.dart';

class DonorListPage extends StatefulWidget {
  @override
  _DonorListPageState createState() => _DonorListPageState();
}

class _DonorListPageState extends State<DonorListPage> {
  final List<Map<String, String>> donors = [
    {"name": "Md. Mehedi Hasan", "bloodGroup": "O+", "address": "Dhaka", "mobile": "01764948871", "age": "25"},
    {"name": "Ayesha Akter", "bloodGroup": "B+", "address": "Chittagong", "mobile": "0987654321", "age": "28"},
    {"name": "Md. Karim", "bloodGroup": "O-", "address": "Khulna", "mobile": "0112233445", "age": "35"},
    {"name": "Fatema Begum", "bloodGroup": "AB+", "address": "Rajshahi", "mobile": "0223344556", "age": "25"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donor List"),
        backgroundColor: const Color.fromARGB(255, 225, 160, 156),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.5,
              ),
              itemCount: donors.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        donors[index]["name"]!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Blood Group: ${donors[index]["bloodGroup"]!}",
                        style: TextStyle(fontSize: 16, color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonorDetailsPage(donor: donors[index]),
                            ),
                          );
                        },
                        child: Text("Details"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
