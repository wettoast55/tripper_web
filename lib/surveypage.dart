// STEP 1: Update survey form to include new fields
// File: surveypage.dart

import 'package:flutter/material.dart';

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> selectedActivities = [];
  String selectedBudget = 'Medium';
  String selectedMonth = 'Any';
  String destinationType = 'International';
  List<String> selectedTravelMethods = [];
  String selectedAccommodation = 'Hotel';
  int tripLength = 5;

  final List<String> activityOptions = [
    'Outdoors', 'Recreational Activities', 'Nightlife', 'Arts', 'Museums', 'Sports'
  ];
  final List<String> travelMethods = ['Flying', 'Driving', 'Train', 'Boat'];
  final List<String> destinationTypes = [
    'International', 'Domestic', 'Europe', 'Asia', 'Australia', 'Northeast US', 'Southeast US', 'Midwest US'
  ];
  final List<String> accommodationOptions = ['Hotel', 'Airbnb', 'Camping'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Survey')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Activities (Multi-select)
                Wrap(
                  spacing: 8,
                  children: activityOptions.map((activity) {
                    return FilterChip(
                      label: Text(activity),
                      selected: selectedActivities.contains(activity),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? selectedActivities.add(activity)
                              : selectedActivities.remove(activity);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Budget Dropdown
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Budget'),
                  value: selectedBudget,
                  items: ['Budget', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedBudget = val!),
                ),

                const SizedBox(height: 16),
                // Month Dropdown
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Month'),
                  value: selectedMonth,
                  items: [
                    'Any', 'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),

                const SizedBox(height: 16),
                // Destination Type
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Destination Type'),
                  value: destinationType,
                  items: destinationTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => destinationType = val!),
                ),

                const SizedBox(height: 16),
                // Travel Methods (Multi-select)
                Wrap(
                  spacing: 8,
                  children: travelMethods.map((method) {
                    return FilterChip(
                      label: Text(method),
                      selected: selectedTravelMethods.contains(method),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? selectedTravelMethods.add(method)
                              : selectedTravelMethods.remove(method);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                // Accommodation Preference
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Accommodation'),
                  value: selectedAccommodation,
                  items: accommodationOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedAccommodation = val!),
                ),

                const SizedBox(height: 16),
                // Trip Length (Slider)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip Length: $tripLength days'),
                    Slider(
                      value: tripLength.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$tripLength',
                      onChanged: (val) => setState(() => tripLength = val.round()),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Save survey data to Firestore and close
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit Survey'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
