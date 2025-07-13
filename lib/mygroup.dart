import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyGroupPage extends StatelessWidget {
  const MyGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //title change for survey status page
      appBar: AppBar(title: const Text("My Group Survey Status")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('surveys').snapshots(),
        builder: (context, snapshot) {

          //show loading indicator while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No survey responses yet."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final email = data['email'] ?? 'Unknown';
              final status = data['completed'] == true ? 'Completed' : 'Pending';
              final activities = data['activities'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Status: $status", style: TextStyle(color: status == 'Completed' ? Colors.green : Colors.orange)),
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("Selected Activities:"),
                        Wrap(
                          spacing: 8,
                          children: activities.map((a) => Chip(label: Text(a.toString()))).toList(),
                        )
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
