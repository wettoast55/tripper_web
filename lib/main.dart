import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:tripper_web/mygroup.dart';
import 'package:tripper_web/surveypage.dart';
import 'package:tripper_web/findtrips.dart';
import 'package:tripper_web/api/recommendation_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  await _ensureLoggedIn();
  print('✅ User is logged in');

  FirebaseFunctions.instanceFor(region: 'us-central1');

  runApp(const MyApp());
}

Future<void> _ensureLoggedIn() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
    print('[Auth] Signed in anonymously: ${auth.currentUser?.uid}');
  } else {
    print('[Auth] Already signed in: ${auth.currentUser?.uid}');
  }

  final prefs = await SharedPreferences.getInstance();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await prefs.setString('userId', uid); // ← Add this line
  }  

  if (uid != null) {
    final groups = await FirebaseFirestore.instance.collection('groups').get();
    for (final group in groups.docs) {
      final memberSnapshot = await group.reference
          .collection('members')
          .where('uid', isEqualTo: uid)
          .get();
      if (memberSnapshot.docs.isNotEmpty) {
        final groupId = group.id;
        final groupPin = group['pin'];
        final creatorId = group['creatorId'];

        await prefs.setString('groupId', groupId);
        await prefs.setString('groupPin', groupPin);
        await prefs.setString('creatorId', creatorId);
        print('[Group] User already in group: $groupId ($groupPin)');
        break;
      }
    }
  }
}

String monthName(int month) {
  const months = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  return months[month];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo - TripCliques',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(136, 79, 97, 255),
        ),
      ),
      home: const MyHomePage(title: 'TripCliques Home Page'),

      // link routes to other pages
      routes: {
        '/survey': (context) => const SurveyFormPage(),
        '/mygroup': (context) => MyGroupPage(
              isInGroup: false,
              onLeaveGroup: () {},
            ),
        '/findtrips': (context) => const FindTripsPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String? groupPin;
  String? groupId;

  @override
  void initState() {
    super.initState();
    _loadGroupState();
  }

  Future<void> _loadGroupState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groupPin = prefs.getString('groupPin');
      groupId = prefs.getString('groupId');
    });
  }

  Future<void> _leaveGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final groupDocId = prefs.getString('groupId');

    if (groupDocId != null && uid != null) {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupDocId);
      final membersRef = groupRef.collection('members');
      final snapshot = await membersRef.where('uid', isEqualTo: uid).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    await prefs.remove('groupId');
    await prefs.remove('groupPin');
    await prefs.remove('creatorId');

    setState(() {
      groupPin = null;
      groupId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have left the group.')),
    );
  }

  List<Widget> get _pages => [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text("page 1 (home/discover)")],
        ),

        FindTripsPage(),
        
        // ✅ Always show MyGroupPage so it can handle all logic itself
        MyGroupPage(
          isInGroup: groupId != null,
          onLeaveGroup: () async {
            await _leaveGroup();
            await _loadGroupState();
          },
          onGroupStatusChanged: () async {
            await _loadGroupState();
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text("page 4 (saved trips)")],
        ),
      ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 44, 189),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
            if (_selectedIndex == 2 && groupPin != null && groupPin!.isNotEmpty)
              Text('PIN: $groupPin', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: SizedBox.expand(child: _pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 2 && groupId != null
          ? FloatingActionButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userId = FirebaseAuth.instance.currentUser?.uid;
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

                  if (snapshot.docs.isNotEmpty) {
                    // ✅ Navigate to FindTripsPage
                    final data = snapshot.docs.first.data();

                    final month = data['startDate'] != null
                        ? DateTime.fromMillisecondsSinceEpoch(data['startDate'].millisecondsSinceEpoch).month
                        : null;

                    final response = await RecommendationApi.fetchRecommendations(
                      activities: List<String>.from(data['activities'] ?? []),
                      budget: data['budget'] ?? "Any",
                      month: month != null ? monthName(month) : "Any",
                      travelMethods: List<String>.from(data['travelMethods'] ?? []),
                      accommodations: List<String>.from(data['accommodations'] ?? []),
                      destinations: List<String>.from(data['destinations'] ?? []),
                      interests: List<String>.from(data['interests'] ?? []),
                      startDate: (data['startDate'] as Timestamp?)?.toDate(),
                      endDate: (data['endDate'] as Timestamp?)?.toDate(),
                    );

                    // Show a dialog or navigate to a new screen with results
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) {
                          final recommendations = response['recommendations'] ?? [];
                          return AlertDialog(
                            title: const Text("Trip Suggestions"),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: recommendations.length,
                                itemBuilder: (_, i) {
                                  final dest = recommendations[i];
                                  return ListTile(
                                    title: Text(dest['name'] ?? ''),
                                    subtitle: Text(dest['description'] ?? ''),
                                    trailing: Text(dest['price'] ?? ''),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Close"),
                              )
                            ],
                          );
                        },
                      );
                    };

                    // if (context.mounted) {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(builder: (_) => const FindTripsPage()),
                    //   );
                    
                  } else {
                    // ❌ No survey found
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Survey Needed"),
                          content: const Text("Please take the survey before searching for trips."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              },

              tooltip: 'Find a group trip',
              child: const Icon(Icons.send_and_archive_rounded),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 208, 212, 255),
        backgroundColor: const Color.fromARGB(255, 0, 119, 254),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'discover/popular',
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'find trips',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'my group',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_add),
            label: 'saved trips',
          ),
        ],
      ),
    );
  }
}
