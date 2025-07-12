import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _msgCtrl = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _user == null) return;

    FirebaseFirestore.instance.collection('chats').add({
      'uid': _user!.uid,
      'name': _user!.displayName ?? 'Anonymous',
      'text': text,
      'ts': FieldValue.serverTimestamp(),
    });
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          /// ✅ Wrap ListView in Expanded so it gets bounded height
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('ts', descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    return ListTile(
                      title: Text(d['name'] ?? 'Unknown'),
                      subtitle: Text(d['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Send a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
