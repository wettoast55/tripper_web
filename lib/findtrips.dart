import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripper_web/api/recommendation_api.dart';
import 'package:tripper_web/cheapest_flights_page.dart';


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
  List<String> travelMethods = [];
  List<String> accommodations = [];
  List<String> destinations = [];
  List<String> interests = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoadingSurvey = true;
  bool isLoadingAi = false;
  List<Map<String, dynamic>> aiDestinations = [];

  final List<String> priceOptions = ["Any", "Budget", "Medium", "High"];
  final List<String> monthOptions = [
    "Any", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
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
          .where('completed', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        final surveyMonth = data['startDate'] != null
            ? _getMonthFromDate(data['startDate'])
            : "Any";

        setState(() {
          userActivities = List<String>.from(data['activities'] ?? []);
          travelMethods = List<String>.from(data['travelMethods'] ?? []);
          accommodations = List<String>.from(data['accommodations'] ?? []);
          destinations = List<String>.from(data['destinations'] ?? []);
          interests = List<String>.from(data['interests'] ?? []);
          startDate = (data['startDate'] as Timestamp?)?.toDate();
          endDate = (data['endDate'] as Timestamp?)?.toDate();

          final budget = data['budget'] ?? "Any";
          selectedPrice = priceOptions.contains(budget) ? budget : "Any";
          selectedMonth = monthOptions.contains(surveyMonth) ? surveyMonth : "Any";

          isLoadingSurvey = false;
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      isLoadingSurvey = false;
    });
  }

  String _getMonthFromDate(dynamic timestamp) {
    if (timestamp == null) return "Any";
    final date = (timestamp as Timestamp).toDate();
    return monthOptions[date.month];
  }

  Future<(DateTime?, DateTime?)> getGroupDateRange() async {
    final prefs = await SharedPreferences.getInstance();
    final groupId = prefs.getString('groupId');

    if (groupId == null) return (null, null);

    final snapshot = await FirebaseFirestore.instance
        .collection('surveys')
        .where('groupId', isEqualTo: groupId)
        .where('completed', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return (null, null);

    DateTime? earliest;
    DateTime? latest;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final start = (data['startDate'] as Timestamp?)?.toDate();
      final end = (data['endDate'] as Timestamp?)?.toDate();
      if (start != null && (earliest == null || start.isBefore(earliest))) {
        earliest = start;
      }
      if (end != null && (latest == null || end.isAfter(latest))) {
        latest = end;
      }
    }

    return (earliest, latest);
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
                          travelMethods: travelMethods,
                          accommodations: accommodations,
                          destinations: destinations,
                          interests: interests,
                          startDate: startDate,
                          endDate: endDate,
                        );

                        final List<dynamic> decoded = response['recommendations'] ?? [];
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
                              onTap: () async {
                                final (groupStart, groupEnd) = await getGroupDateRange();
                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheapestFlightsPage(
                                      destination: dest["name"] ?? "",
                                      startDate: groupStart,
                                      endDate: groupEnd,
                                    ),
                                  ),
                                );
                              },
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
