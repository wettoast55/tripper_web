import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final TextEditingController emailController = TextEditingController();
  final List<String> allActivities = ['Hiking', 'Museum', 'Beach', 'Food Tour'];
  final Set<String> selectedActivities = {};

  String? groupId;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  /// Load userId and groupId from SharedPreferences
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groupId = prefs.getString('groupId');
      userId = prefs.getString('userId');
    });
  }

  /// Submit survey response to Firestore
  Future<void> submitSurvey() async {
    final email = emailController.text.trim();
    if (email.isEmpty || groupId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('surveys').add({
      'email': email,
      'completed': true,
      'activities': selectedActivities.toList(),
      'groupId': groupId,
      'userId': userId,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey submitted!')),
    );

    emailController.clear();
    selectedActivities.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Preferences Survey')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Email", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: "Enter your email"),
            ),
            const SizedBox(height: 20),

            const Text("Select Activities", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: allActivities.map((activity) {
                final isSelected = selectedActivities.contains(activity);
                return FilterChip(
                  label: Text(activity),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedActivities.add(activity);
                      } else {
                        selectedActivities.remove(activity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: submitSurvey,
                child: const Text("Submit Survey"),
              ),
            )
          ],
        ),
      ),
    );
  }
}