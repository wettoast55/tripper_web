import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final List<String> allActivities = ['Hiking', 'Museum', 'Beach', 'Food Tour'];
  final Set<String> selectedActivities = {};

  String? groupId;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groupId = prefs.getString('groupId');
      userId = prefs.getString('userId');
    });
  }

  Future<void> submitSurvey() async {
    if (groupId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing group or user information.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('surveys').add({
      'completed': true,
      'activities': selectedActivities.toList(),
      'groupId': groupId,
      'userId': userId,
      'timestamp': Timestamp.now(),
    });

    // Show success message before closing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey submitted!')),
    );

    // Close the page cleanly
    Navigator.of(context).pop();
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
