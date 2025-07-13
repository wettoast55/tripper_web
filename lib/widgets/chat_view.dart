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

  // send message function
  // This function is called when the user presses the send button.
  void _send() async{
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _user == null) {
      print('[SEND] empty message or user not logged in');
      // If the message is empty or the user is not logged in, do nothing.
    return;
    }

    // Log the message being sent (if)
    print('[SEND] Sending message: $text from ${_user!.uid}');

    try {
    await FirebaseFirestore.instance.collection('chats').add({
      'uid': _user!.uid,
      'name': _user!.displayName ?? 'Anonymous',
      'text': text,
      'ts': FieldValue.serverTimestamp(),
    });

    print('[SEND] Message sent successfully');
    } catch (e) {
      print('[SEND] Error sending message: $e');
      // Handle error, e.g., show a snackbar or dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    print('Current user: ${FirebaseAuth.instance.currentUser}');
   
    // Check if user is logged in
    if (_user == null) {
      return Center(
        child: Text('Please log in to chat'),
      );
    }
    print('Building ChatView for user: ${_user!.uid}');
    // Build the chat view
    // Use SafeArea to avoid notches and system UI overlaps

    return SafeArea(
      child: Column(
        children: [
          /// ✅ Wrap ListView in Expanded so it gets bounded height
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  // .orderBy('ts', descending: true)
                  //testing without ordering if is broken
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

                    // more robust way to access data
                    final d = docs[i];

                    // Check if data is empty or null, d.data gives plain MAP which
                    // can be null, so we need to check it.
                    final data = d.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['name'] ?? 'Unknown'),
                      subtitle: Text(data['text'] ?? ''),
                    );

                    // //will cause error if 'name' does not exist..
                    // final d = docs[i];
                    // return ListTile(
                    //   title: Text(d['name'] ?? 'Unknown'),
                    //   subtitle: Text(d['text'] ?? ''),
                    // );
                    
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
