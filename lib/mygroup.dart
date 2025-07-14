import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:html' as html; // for web invite link sharing
import 'package:shared_preferences/shared_preferences.dart'; // to persist session across reloads

class MyGroupPage extends StatefulWidget {
  const MyGroupPage({super.key});

  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  String? groupId;
  String? groupPin;
  String? creatorId;
  String? userId;
  final TextEditingController pinController = TextEditingController();

  /// Initializes user ID and optionally joins group via URL (?pin=xxxx)
  @override
  void initState() {
    super.initState();
    _loadUserState();
  }

  Future<void> _loadUserState() async {
    final prefs = await SharedPreferences.getInstance();

    userId = prefs.getString('userId') ?? 'user_\${DateTime.now().millisecondsSinceEpoch % 1000000}';
    await prefs.setString('userId', userId!);

    groupId = prefs.getString('groupId');
    groupPin = prefs.getString('groupPin');
    creatorId = prefs.getString('creatorId');

    final pinParam = Uri.base.queryParameters['pin'];
    if (pinParam != null && groupId == null) {
      pinController.text = pinParam;
      await joinGroup(auto: true);
    }
    setState(() {});
  }

  /// Creates a new group, stores creator ID, and saves locally
  Future<void> createGroup() async {
    final random = Random();
    final pin = (1000 + random.nextInt(9000)).toString();

    final doc = await FirebaseFirestore.instance.collection('groups').add({
      'pin': pin,
      'createdAt': Timestamp.now(),
      'creatorId': userId,
    });

    groupId = doc.id;
    groupPin = pin;
    creatorId = userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groupId', groupId!);
    await prefs.setString('groupPin', groupPin!);
    await prefs.setString('creatorId', creatorId!);

    await doc.collection('members').add({
      'nickname': 'Creator_${userId!.substring(userId!.length - 4)}',
      'status': 'joined',
      'joinedAt': Timestamp.now(),
      'uid': userId,
    });

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group created successfully!')),
    );
  }

  /// Joins an existing group by PIN. If auto=true, suppress error snackbar
  Future<void> joinGroup({bool auto = false}) async {
    final enteredPin = pinController.text.trim();
    if (enteredPin.isEmpty) return;

    final query = await FirebaseFirestore.instance
        .collection('groups')
        .where('pin', isEqualTo: enteredPin)
        .get();

    if (query.docs.isEmpty) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No group found with that PIN')),
        );
      }
      return;
    }

    final doc = query.docs.first;

    groupId = doc.id;
    groupPin = enteredPin;
    creatorId = doc['creatorId'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groupId', groupId!);
    await prefs.setString('groupPin', groupPin!);
    await prefs.setString('creatorId', creatorId!);

    final membersRef = doc.reference.collection('members');
    final existing = await membersRef.where('uid', isEqualTo: userId).get();

    if (existing.docs.isEmpty) {
      await membersRef.add({
        'nickname': 'Guest_\${userId!.substring(userId!.length - 4)}',
        'status': 'joined',
        'joinedAt': Timestamp.now(),
        'uid': userId,
      });
    }

    if (!auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully!')),
      );
    }

    setState(() {});
  }

  /// Generates and copies a shareable invite link with the group PIN
  void copyInviteLink() {
    final baseUrl = html.window.location.origin;
    final link = '\$baseUrl?pin=\$groupPin';

    html.window.navigator.clipboard?.writeText(link);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite link copied: \$link')),
    );
  }

  /// Allows the group creator to update another member's status
  void updateMemberStatus(String memberDocId, String newStatus) {
    if (groupId == null) return;

    FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberDocId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Group")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// === Group Creation Section ===
            const Text("Create a New Group", style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: createGroup,
              child: const Text("Create Group"),
            ),
            if (groupPin != null)
              Row(
                children: [
                  Text("Group PIN: \$groupPin", style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.link),
                    tooltip: "Copy Invite Link",
                    onPressed: copyInviteLink,
                  )
                ],
              ),

            const SizedBox(height: 24),

            /// === Join Existing Group ===
            const Text("Join a Group via PIN", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pinController,
                    decoration: const InputDecoration(labelText: "Enter Group PIN"),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: joinGroup,
                  child: const Text("Join"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// === Group Members View ===
            if (groupId != null) ...[
              const Text("Group Members", style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final docs = snapshot.data!.docs;

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nickname = data['nickname'] ?? 'Guest';
                      final status = data['status'] ?? 'unknown';
                      final isCreator = userId == creatorId;

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(nickname),
                        subtitle: Text("Status: \$status"),
                        trailing: isCreator
                            ? PopupMenuButton<String>(
                                onSelected: (value) => updateMemberStatus(doc.id, value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'invited', child: Text('Invited')),
                                  PopupMenuItem(value: 'joined', child: Text('Joined')),
                                  PopupMenuItem(value: 'declined', child: Text('Declined')),
                                ],
                                icon: const Icon(Icons.edit),
                              )
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            /// === Survey Status (Only show for current group) ===
            const Text("Survey Status", style: TextStyle(fontWeight: FontWeight.bold)),
            if (groupId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('surveys')
                    .where('groupId', isEqualTo: groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No survey responses yet.");
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final email = data['email'] ?? 'Unknown';
                      final status = data['completed'] == true ? 'Completed' : 'Pending';
                      final activities = data['activities'] as List<dynamic>? ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Status: \$status",
                                  style: TextStyle(color: status == 'Completed' ? Colors.green : Colors.orange)),
                              if (activities.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text("Selected Activities:"),
                                Wrap(
                                  spacing: 8,
                                  children: activities.map((a) => Chip(label: Text(a.toString()))).toList(),
                                )
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}