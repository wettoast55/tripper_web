import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  String? groupId;
  String? userId;
  String? existingSurveyDocId;

  final Set<String> selectedActivities = {};
  final Set<String> selectedTravelMethods = {};
  final Set<String> selectedAccommodations = {};
  final Set<String> selectedDestinations = {};
  final Set<String> selectedInterests = {};
  final List<String> allActivities = ['Hiking', 'Museum', 'Beach', 'Food Tour'];
  final List<String> travelMethods = ['Fly', 'Drive', 'Train', 'Boat'];
  final List<String> accommodations = ['Hotel', 'Airbnb', 'Camping'];
  final List<String> destinations = ['Continental US', 'International', 'Northeast US', 'Southwest US'];
  final List<String> interests = ['Outdoors', 'Recreation', 'Nightlife', 'Relaxation', 'History'];

  final TextEditingController budgetController = TextEditingController();
  DateTimeRange? selectedDateRange;

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
        selectedActivities.addAll(List<String>.from(data['activities'] ?? []));
        selectedTravelMethods.addAll(List<String>.from(data['travelMethods'] ?? []));
        selectedAccommodations.addAll(List<String>.from(data['accommodations'] ?? []));
        selectedDestinations.addAll(List<String>.from(data['destinations'] ?? []));
        selectedInterests.addAll(List<String>.from(data['interests'] ?? []));
        budgetController.text = data['budget'] ?? '';
        if (data['startDate'] != null && data['endDate'] != null) {
          selectedDateRange = DateTimeRange(
            start: (data['startDate'] as Timestamp).toDate(),
            end: (data['endDate'] as Timestamp).toDate(),
          );
        }

        setState(() {});
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

    final data = {
      'activities': selectedActivities.toList(),
      'travelMethods': selectedTravelMethods.toList(),
      'accommodations': selectedAccommodations.toList(),
      'destinations': selectedDestinations.toList(),
      'interests': selectedInterests.toList(),
      'budget': budgetController.text.trim(),
      'startDate': selectedDateRange?.start,
      'endDate': selectedDateRange?.end,
      'completed': true,
      'groupId': groupId,
      'userId': userId,
      'timestamp': Timestamp.now(),
    };

    if (existingSurveyDocId != null) {
      await FirebaseFirestore.instance.collection('surveys').doc(existingSurveyDocId).update(data);
    } else {
      final newDoc = await FirebaseFirestore.instance.collection('surveys').add(data);
      existingSurveyDocId = newDoc.id;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey saved!')),
    );

    Navigator.of(context).pop();
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  Widget buildChips(String label, List<String> options, Set<String> selectedSet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedSet.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedSet.add(option);
                  } else {
                    selectedSet.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Preferences Survey')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildChips("Select Activities", allActivities, selectedActivities),
            buildChips("Travel Methods", travelMethods, selectedTravelMethods),
            buildChips("Accommodations", accommodations, selectedAccommodations),
            buildChips("Destinations", destinations, selectedDestinations),
            buildChips("Interests", interests, selectedInterests),
            const Text("Travel Budget", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(hintText: "e.g., \$500 - \$1000"),
            ),
            const SizedBox(height: 16),
            const Text("Date Range", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: pickDateRange,
              child: Text(selectedDateRange == null
                  ? "Select Date Range"
                  : "${selectedDateRange!.start.month}/${selectedDateRange!.start.day}/${selectedDateRange!.start.year} - ${selectedDateRange!.end.month}/${selectedDateRange!.end.day}/${selectedDateRange!.end.year}"),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: submitSurvey,
                child: Text(existingSurveyDocId != null ? "Update Survey" : "Submit Survey"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
