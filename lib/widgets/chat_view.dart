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

  // called when the widget is first created
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLoggedInAndName();
    });
  }

  // Function to check if user already has a name, if not, prompt for one
  Future<void> _ensureLoggedInAndName() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }

    final user = auth.currentUser;
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      await _askForUsername();
    }
  }

  // Function to prompt user for a username
  Future<void> _askForUsername() async {
    String? chosenName;
    await showDialog(
      context: context,
      builder: (context) {
        final _nameCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Choose a username'),
          content: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                chosenName = _nameCtrl.text.trim();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // If the user provided a name, update the Firebase Auth user profile
    // and print a message
    if (chosenName != null && chosenName!.isNotEmpty) {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(chosenName);
      print('[User] Set name to $chosenName');
    }
  }

  // send message function
  // This function is called when the user presses the send button.
  void _send() async{

    // Check if the message is empty or if the user is not logged in or is first time user
    final user = FirebaseAuth.instance.currentUser;
    final text = _msgCtrl.text.trim();

    // If the message is empty or the user is not logged in, do nothing.
    if (text.isEmpty || user == null) {
      print('[SEND] Empty message or user not signed in');
      return;
    }

    // Log the message being sent (if)
    print('[SEND] Sending message: $text from ${user.uid}');

    // Add the message to Firestore
    // Use try-catch to handle any errors that may occur during the send operation
    try {
    await FirebaseFirestore.instance.collection('chats').add({
      'uid': user.uid,
      'name': user.displayName ?? 'Anonymous',
      'text': text,
      'ts': FieldValue.serverTimestamp(),
    });

    // If successful, print a success message
    // and clear the message input field
    print('[SEND] Message sent successfully');
    } catch (e) {
      print('[SEND] Error sending message: $e');
      // Handle error, e.g., show a snackbar or dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }

    // Clear the message input field after sending
    _msgCtrl.clear();
  }

  // This method builds the UI for the chat view, including the message list and input field
  @override
  Widget build(BuildContext context) {
   
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;

    print('Current user: ${FirebaseAuth.instance.currentUser}');

    // If user is not logged in, show a message to log in
    if (user == null) {
      return Center(
        child: Text('Please log in to chat'),
      );
    }
    print('Building ChatView for user: ${user.uid}');

    // Use SafeArea to avoid notches and system UI overlaps
    return SafeArea(
      child: Column(
        children: [

          // Header with user info
          Expanded(
            child: StreamBuilder<QuerySnapshot>(

              // Listen to the 'chats' collection in Firestore
              // Order by timestamp in descending order to show the latest messages first
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('ts', descending: true)
                  //testing without ordering if is broken
                  .snapshots(),
              builder: (ctx, snapshot) {

                // If the snapshot has an error, show an error message
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If the snapshot has no data, show a message
                final docs = snapshot.data!.docs;

                // If there are no messages, show a message
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

          // Input bar for sending messages
          // This is a simple text field with a send button
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

                    // enter key to send message
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        _send();
                      }
                    },
                    
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
