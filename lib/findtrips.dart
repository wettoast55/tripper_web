import 'package:flutter/material.dart';
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

  // List to hold dynamic results from AI
  List<Map<String, String>> aiDestinations = [];

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = aiDestinations.where((destination) {
      final nameMatch = destination["name"]!
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final priceMatch = selectedPrice == "Any" ||
          destination["price"] == selectedPrice;

      final monthMatch = selectedMonth == "Any" ||
          destination["bestMonths"]?.contains(selectedMonth) == true;

      return nameMatch && priceMatch && monthMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Trips"),
      ),
      body: Padding(
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
                // Price filter dropdown
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
                // Month filter dropdown
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

            // Find Trips with AI Button
            ElevatedButton(
              onPressed: () async {
                final result = await RecommendationApi.fetchRecommendations(
                  activities: ["Beach", "Museum"], // Replace with real user prefs later
                  budget: selectedPrice,
                  month: selectedMonth,
                );

                // Parse GPT string response into structured format
                final List<Map<String, String>> parsed = [];
                final lines = result.split('\n');
                for (var line in lines) {
                  if (line.trim().isEmpty) continue;

                  final nameMatch = RegExp(r'^\d+\.\s*(.*?)(?= -|:|\n|\r|\$)').firstMatch(line);
                  final descMatch = RegExp(r'Description[:\-]?\s*(.*?)(?=Flight|\\$)').firstMatch(line);
                  final priceMatch = RegExp(r'Flight Price[:\-]?\s*(.*?)(?=Top Attraction|\\$)').firstMatch(line);
                  final attractionMatch = RegExp(r'Top Attraction[:\-]?\s*(.*)').firstMatch(line);

                  if (nameMatch != null) {
                    parsed.add({
                      "name": nameMatch.group(1)?.trim() ?? "Unknown",
                      "description": descMatch?.group(1)?.trim() ?? "",
                      "price": priceMatch?.group(1)?.trim() ?? "",
                      "attraction": attractionMatch?.group(1)?.trim() ?? "",
                    });
                  }
                }

                setState(() {
                  aiDestinations = parsed;
                });
              },
              child: const Text("Find Trips with AI"),
            ),

            const SizedBox(height: 16),

            // Trip Result List
            Expanded(
              child: aiDestinations.isEmpty
                  ? const Center(child: Text("No destinations yet. Try 'Find Trips with AI'."))
                  : ListView.builder(
                      itemCount: filteredDestinations.length,
                      itemBuilder: (context, index) {
                        final dest = filteredDestinations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(dest["name"] ?? "Unknown"),
                            subtitle: Text(dest["description"] ?? ""),
                            trailing: Text(dest["price"] ?? ""),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}