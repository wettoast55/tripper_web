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
  String? existingSurveyDocId;

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    groupId = prefs.getString('groupId');
    userId = prefs.getString('userId');

    if (groupId != null && userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        existingSurveyDocId = doc.id;

        final data = doc.data();
        final previousActivities = (data['activities'] as List<dynamic>?) ?? [];

        setState(() {
          selectedActivities.addAll(previousActivities.cast<String>());
        });
      }
    }
  }

  Future<void> submitSurvey() async {
    if (groupId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing group or user information.')),
      );
      return;
    }

    if (existingSurveyDocId != null) {
      // Update existing survey
      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(existingSurveyDocId)
          .update({
        'activities': selectedActivities.toList(),
        'completed': true,
        'timestamp': Timestamp.now(),
      });
    } else {
      // Create a new survey
      final newDoc = await FirebaseFirestore.instance.collection('surveys').add({
        'activities': selectedActivities.toList(),
        'completed': true,
        'groupId': groupId,
        'userId': userId,
        'timestamp': Timestamp.now(),
      });
      existingSurveyDocId = newDoc.id;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey saved!')),
    );

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
                child: Text(existingSurveyDocId != null ? "Update Survey" : "Submit Survey"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
