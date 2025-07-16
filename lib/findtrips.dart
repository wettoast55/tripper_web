import 'package:flutter/material.dart';

// You can later move this to a separate file or Firestore
const sampleDestinations = [
  {
    "name": "Bali, Indonesia",
    "bestMonths": ["April", "May", "June", "September"],
    "price": "Medium",
    "activities": ["Beach", "Food Tour", "Hiking"],
    "description": "A tropical paradise known for beaches and temples."
  },
  {
    "name": "Kyoto, Japan",
    "bestMonths": ["March", "April", "October"],
    "price": "High",
    "activities": ["Museum", "Food Tour"],
    "description": "Historic city famous for shrines and cherry blossoms."
  },
  {
    "name": "Lisbon, Portugal",
    "bestMonths": ["May", "June", "September"],
    "price": "Budget",
    "activities": ["Food Tour", "Museum", "Beach"],
    "description": "A charming city with coastal views and rich history."
  },
  {
    "name": "Reykjavik, Iceland",
    "bestMonths": ["June", "July", "August"],
    "price": "High",
    "activities": ["Hiking", "Museum"],
    "description": "Explore glaciers, volcanoes, and unique landscapes."
  },
];

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

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = sampleDestinations.where((destination) {
      final nameMatch = destination["name"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final priceMatch = selectedPrice == "Any" ||
          destination["price"] == selectedPrice;

      final monthMatch = selectedMonth == "Any" ||
          (destination["bestMonths"] as List).contains(selectedMonth);

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
                // Price filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Price",
                    ),
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
                // Month filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Best Month",
                    ),
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
            // Results
            Expanded(
              child: filteredDestinations.isEmpty
                  ? const Center(child: Text("No destinations match your filters."))
                  : ListView.builder(
                      itemCount: filteredDestinations.length,
                      itemBuilder: (context, index) {
                        final dest = filteredDestinations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(dest["name"] as String),
                            subtitle: Text(dest["description"] as String),
                            trailing: Text(dest["price"] as String),
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
