import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripper_web/surveypage.dart';

class MyGroupPage extends StatefulWidget {
  final bool isInGroup;
  final VoidCallback onLeaveGroup;
  final Future<void> Function()? onGroupStatusChanged;

  const MyGroupPage({
    super.key,
    required this.isInGroup,
    required this.onLeaveGroup,
    this.onGroupStatusChanged,
  });

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
    userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch % 1000000}';
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

  Future<void> _editGroupName() async {
    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Group Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Group Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Save"))
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && groupId != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({'name': newName});

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name updated!')),
      );
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
      'name': 'Unnamed Group',
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
    if (widget.onGroupStatusChanged != null) {
      await widget.onGroupStatusChanged!();
    }

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

    setState(() {});
    if (widget.onGroupStatusChanged != null) {
      await widget.onGroupStatusChanged!();
    }

    if (!auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully!')),
      );
    }
  }

  Future<bool> _isSurveyCompleted() async {
    if (groupId == null || userId == null) return false;
    final snapshot = await FirebaseFirestore.instance
        .collection('surveys')
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  void copyInviteLink() {
    final baseUrl = html.window.location.origin;
    final link = '$baseUrl?pin=$groupPin';
    html.window.navigator.clipboard?.writeText(link);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite link copied: $link')),
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
      appBar: AppBar(

        // Display group name and survey statuses in appbar up top
        title: widget.isInGroup && groupId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
                builder: (context, groupSnapshot) {
                  if (!groupSnapshot.hasData) {
                    return const Text("My Group");
                  }
                  final data = groupSnapshot.data!.data() as Map<String, dynamic>;
                  final groupName = (data['name'] ?? 'Unnamed Group') as String;
                  final isCreator = userId == creatorId;

                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          groupName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCreator)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Edit Group Name',
                          onPressed: _editGroupName,
                        ),
                      const SizedBox(width: 8),
                      // This nested StreamBuilder gets survey and member counts
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .collection('members')
                            .snapshots(),
                        builder: (context, membersSnapshot) {
                          if (!membersSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final totalUsers = membersSnapshot.data!.docs.length;

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('surveys')
                                .where('groupId', isEqualTo: groupId)
                                .snapshots(),
                            builder: (context, surveysSnapshot) {
                              if (!surveysSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              final completedSurveys = surveysSnapshot.data!.docs.length;

                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  "📝 $completedSurveys/$totalUsers",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              )
            : const Text("My Group"),
      ),


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
                  Text("Group PIN: $groupPin", style: const TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.link), tooltip: "Copy Invite Link", onPressed: copyInviteLink),
                      ElevatedButton(onPressed: widget.onLeaveGroup, child: const Text("Leave Group")),
                    ],
                  )
                ],
              ),
            if (widget.isInGroup && groupId != null) ...[
              const SizedBox(height: 24),
              const Text("Group Members", style: TextStyle(fontWeight: FontWeight.bold)),

              // widgets for members, surveys, ect outside groupname/pin settings
              if (widget.isInGroup && groupId != null) ...[
                const SizedBox(height: 24),
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
                        final isSelf = data['uid'] == userId;
                        return FutureBuilder<bool>(
                          future: isSelf ? _isSurveyCompleted() : Future.value(true),
                          builder: (context, surveySnapshot) {
                            final surveyDone = surveySnapshot.data ?? false;
                            return ListTile(
                              leading: const Icon(Icons.person),

                              // Display nickname and allow editing if it's the user's own entry
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      nickname,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelf)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      tooltip: 'Edit nickname',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _editNickname(doc.id, nickname),
                                    ),
                                ],
                              ),

                              subtitle: Text(
                                "Survey Status: ${surveyDone ? 'Completed' : 'Incomplete'}",
                                style: TextStyle(
                                  color: surveyDone ? Colors.green : Colors.orange,
                                ),
                              ),
                              trailing: isSelf
                                  ? IconButton(
                                      icon: Icon(
                                        surveyDone ? Icons.replay_circle_filled_rounded : Icons.assignment,
                                      ),
                                      tooltip: surveyDone ? "Edit Survey" : "Take Survey",
                                      onPressed: () {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (context) => const SurveyFormPage(),
                                              ),
                                            )
                                            .then((_) {
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  surveyDone ? 'Survey updated!' : 'Survey completed!',
                                                ),
                                              ),
                                            );
                                          }
                                        });
                                      },
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
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text("Survey Status", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        final status = data['completed'] == true ? 'Completed' : 'Pending';

                        // list of survey answers below each user
                        final budget = data['budget'] ?? 'N/A';
                        final startDate = (data['startDate'] as Timestamp?)?.toDate();
                        final endDate = (data['endDate'] as Timestamp?)?.toDate();
                        final travelMethods = List<String>.from(data['travelMethods'] ?? []);
                        final accommodations = List<String>.from(data['accommodations'] ?? []);
                        final destinations = List<String>.from(data['destinations'] ?? []);
                        final interests = List<String>.from(data['interests'] ?? []);
                        final activities = List<String>.from(data['activities'] ?? []);

                        final nickname = data['nickname'] ?? 'Guest';

                        // FORMATTING FOR SAID LIST OF ACTIVITIES
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Status: ${data['completed'] == true ? 'Completed' : 'Pending'}",
                                    style: TextStyle(color: data['completed'] == true ? Colors.green : Colors.orange)),

                                const SizedBox(height: 8),
                                Text("Budget: $budget"),
                                if (startDate != null && endDate != null)
                                  Text("Dates: ${startDate.month}/${startDate.day}/${startDate.year} - ${endDate.month}/${endDate.day}/${endDate.year}"),

                                if (travelMethods.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text("Travel Methods:"),
                                  Wrap(spacing: 8, children: travelMethods.map((m) => Chip(label: Text(m))).toList()),
                                ],

                                if (accommodations.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text("Accommodations:"),
                                  Wrap(spacing: 8, children: accommodations.map((a) => Chip(label: Text(a))).toList()),
                                ],

                                if (destinations.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text("Destinations:"),
                                  Wrap(spacing: 8, children: destinations.map((d) => Chip(label: Text(d))).toList()),
                                ],

                                if (interests.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text("Interests:"),
                                  Wrap(spacing: 8, children: interests.map((i) => Chip(label: Text(i))).toList()),
                                ],

                                if (activities.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text("Selected Activities:"),
                                  Wrap(spacing: 8, children: activities.map((a) => Chip(label: Text(a))).toList()),
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

            ],
          ],
        ),
      ),
    );
  }
}
