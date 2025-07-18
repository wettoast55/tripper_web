import 'dart:convert'; // Needed for jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripper_web/api/recommendation_api.dart';

class FindTripsPage extends StatefulWidget {
  const FindTripsPage({super.key});

  @override
  State<FindTripsPage> createState() => _FindTripsPageState();
}

class _FindTripsPageState extends State<FindTripsPage> {
  String searchQuery = "";
  String selectedPrice = "Any";
  String selectedMonth = "Any";
  List<String> userActivities = [];
  bool isLoadingSurvey = true;
  bool isLoadingAi = false;
  List<Map<String, dynamic>> aiDestinations = [];

  final List<String> priceOptions = ["Any", "Budget", "Medium", "High"];
  final List<String> monthOptions = [
    "Any",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    loadSurveyPreferences();
  }

  Future<void> loadSurveyPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final groupId = prefs.getString('groupId');

    if (userId != null && groupId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .where('userId', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        setState(() {
          userActivities = List<String>.from(data['activities'] ?? []);
          selectedPrice = data['budget'] ?? "Any";
          selectedMonth = data['month'] ?? "Any";
          isLoadingSurvey = false;
        });
        return;
      }
    }

    setState(() {
      isLoadingSurvey = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Trips")),
      body: isLoadingSurvey
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Search destinations",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Price"),
                          value: selectedPrice,
                          items: priceOptions
                              .map((price) => DropdownMenuItem(
                                    value: price,
                                    child: Text(price),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPrice = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Best Month"),
                          value: selectedMonth,
                          items: monthOptions
                              .map((month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(month),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Button
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoadingAi = true;
                      });

                      try {
                        final response = await RecommendationApi.fetchRecommendations(

                          activities: userActivities,
                          budget: selectedPrice,
                          month: selectedMonth,
                        );

                        // Result is already a JSON string, so parse it
                        final List<dynamic> decoded = response['recommendations'];
                        if (!mounted) return;

                        setState(() {
                          aiDestinations = decoded.cast<Map<String, dynamic>>();
                          isLoadingAi = false;
                        });
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          isLoadingAi = false;
                        });
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Error"),
                            content: Text("Failed to fetch AI recommendations: $e"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close")),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text("Find Trips with AI"),
                  ),

                  const SizedBox(height: 16),

                  if (isLoadingAi)
                    const CircularProgressIndicator()
                  else if (aiDestinations.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: aiDestinations.length,
                        itemBuilder: (context, index) {
                          final dest = aiDestinations[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(dest["name"] ?? ""),
                              subtitle: Text(dest["description"] ?? ""),
                              trailing: Text(dest["price"] ?? ""),
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
    );
  }
}
