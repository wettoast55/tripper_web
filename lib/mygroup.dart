import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

class MyGroupPage extends StatefulWidget {
  final bool isInGroup;
  final VoidCallback onLeaveGroup;

  const MyGroupPage({super.key, required this.isInGroup, required this.onLeaveGroup});

  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  String? groupId;
  String? groupPin;
  String? creatorId;
  String? userId;
  final TextEditingController pinController = TextEditingController();

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

  Future<String?> _promptNickname({required String defaultName}) async {
    final controller = TextEditingController(text: defaultName);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set your nickname"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nickname"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Save"))
        ],
      ),
    );
  }

  Future<void> _editNickname(String memberDocId, String currentName) async {
    final newName = await _promptNickname(defaultName: currentName);
    if (newName != null && newName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(memberDocId)
          .update({'nickname': newName});
    }
  }

  Future<void> createGroup() async {
    if (widget.isInGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only join one group.")),
      );
      return;
    }

    final nickname = await _promptNickname(defaultName: 'Creator');
    if (nickname == null || nickname.isEmpty) return;

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
      'nickname': nickname,
      'status': 'joined',
      'joinedAt': Timestamp.now(),
      'uid': userId,
    });

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group created successfully!')),
    );
  }

  Future<void> joinGroup({bool auto = false}) async {
    if (widget.isInGroup) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're already in a group.")),
        );
      }
      return;
    }

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
      final nickname = await _promptNickname(defaultName: 'Guest');
      if (nickname == null || nickname.isEmpty) return;

      await membersRef.add({
        'nickname': nickname,
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

  void copyInviteLink() {
    final baseUrl = html.window.location.origin;
    final link = '\$baseUrl?pin=\$groupPin';
    html.window.navigator.clipboard?.writeText(link);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite link copied: \$link')),
    );
  }

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
            if (!widget.isInGroup) ...[
              const Text("Create a New Group", style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(onPressed: createGroup, child: const Text("Create Group")),
              const SizedBox(height: 24),
              const Text("Join a Group via PIN", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextField(controller: pinController, decoration: const InputDecoration(labelText: "Enter Group PIN"))),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: joinGroup, child: const Text("Join")),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (widget.isInGroup && groupPin != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Group PIN: \$groupPin", style: const TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.link), tooltip: "Copy Invite Link", onPressed: copyInviteLink),
                      ElevatedButton(onPressed: widget.onLeaveGroup, child: const Text("Leave Group")),
                    ],
                  )
                ],
              ),
            if (groupId != null) ...[
              const Text("Group Members", style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').doc(groupId).collection('members').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nickname = data['nickname'] ?? 'Guest';
                      final status = data['status'] ?? 'unknown';
                      final isCreator = userId == creatorId;
                      final isSelf = data['uid'] == userId;
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(nickname),
                        subtitle: Text("Status: \$status"),
                        trailing: isSelf
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit nickname',
                                onPressed: () => _editNickname(doc.id, nickname),
                              )
                            : isCreator
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
            const Text("Survey Status", style: TextStyle(fontWeight: FontWeight.bold)),
            if (groupId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('surveys').where('groupId', isEqualTo: groupId).snapshots(),
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
                              Text("Status: \$status", style: TextStyle(color: status == 'Completed' ? Colors.green : Colors.orange)),
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
