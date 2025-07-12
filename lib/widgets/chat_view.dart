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
  final _user = FirebaseAuth.instance.currentUser!;

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    FirebaseFirestore.instance.collection('chats').add({
      'uid': _user.uid,
      'name': _user.displayName ?? 'Anon',
      'text': text,
      'ts': FieldValue.serverTimestamp(),
    });
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .orderBy('ts', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            final docs = snap.data!.docs;
            return ListView.builder(
              reverse: true,
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i];
                return ListTile(
                  title: Text(d['name']),
                  subtitle: Text(d['text']),
                );
              },
            );
          },
        ),
      ),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            decoration: const InputDecoration(labelText: 'Send a message'),
          ),
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: _send),
      ]),
    ]);
  }
}
