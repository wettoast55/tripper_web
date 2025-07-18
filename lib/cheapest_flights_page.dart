import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripper_web/api/deals_api.dart';

class CheapestFlightsPage extends StatefulWidget {
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;

  const CheapestFlightsPage({
    super.key,
    required this.destination,
    this.startDate,
    this.endDate,
  });

  @override
  State<CheapestFlightsPage> createState() => _CheapestFlightsPageState();
}

class _CheapestFlightsPageState extends State<CheapestFlightsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> deals = [];
  String error = "";

  @override
  void initState() {
    super.initState();
    fetchFlightDeals();
  }

  Future<void> fetchFlightDeals() async {
    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      // TODO: Replace "JFK" with actual origin from survey or user profile
      final response = await DealsApi.fetchLiveDeals(
        origin: "JFK",
        maxPrice: 1000,
      );

      setState(() {
        deals = List<Map<String, dynamic>>.from(response['deals'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Failed to fetch flight deals: $e";
      });
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flights to ${widget.destination}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : deals.isEmpty
                  ? const Center(child: Text("No deals found."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: deals.length,
                      itemBuilder: (context, index) {
                        final deal = deals[index];
                        return Card(
                          child: ListTile(
                            title: Text("Destination: ${deal['destination']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Price: \$${deal['price'] ?? '-'}"),
                                Text("Departure: ${formatDate(deal['departure_date'])}"),
                                Text("Return: ${formatDate(deal['return_date'])}"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
