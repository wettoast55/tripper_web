import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for storing survey data

import 'package:http/http.dart' as http;
import 'dart:convert';

class SurveyInviteDialog extends StatefulWidget {
  const SurveyInviteDialog({super.key});

  @override
  State<SurveyInviteDialog> createState() => _SurveyInviteDialogState();
}

class _SurveyInviteDialogState extends State<SurveyInviteDialog> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

Future<void> _sendSurveyInvite() async {
  final email = _emailCtrl.text.trim();
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  if (email.isEmpty || !emailRegex.hasMatch(email)) {
    setState(() {
      _message = 'Please enter a valid email address.';
    });
    return;
  }

  final token = DateTime.now().millisecondsSinceEpoch.toString();

  setState(() {
    _loading = true;
    _message = null;
  });

  // try {
    // final sendSurvey = FirebaseFunctions.instance.httpsCallable('sendSurveyEmail');
    
    // await sendSurvey.call({
    //   'email': email,
    //   'token': token,
    // });

  final response = await http.post(
    Uri.parse('https://your-backend.com/send-survey'), // replace with your real backend URL
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'token': token}),
  );

  if (response.statusCode == 200) {
    setState(() {
      _message = 'Survey invite sent to $email!';
      _emailCtrl.clear();
    });
  } else {
    setState(() {
      _message = 'Failed to send: ${response.body}';
    });
  }

    // // Store the survey invite in Firestore
    // await FirebaseFirestore.instance.collection('surveys').doc(token).set({
    //   'email': email,
    //   'token': token,
    //   'sentAt': Timestamp.now(),
    //   'completed': false,
    // });

    // setState(() {
    //   _message = 'Survey invite sent to $email!';
    //   _emailCtrl.clear();
    // });
  // } catch (e) {
  //   setState(() {
  //     _message = 'Failed to send: $e';
  //   });
  // } finally {
  //   setState(() => _loading = false);
  // }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Send Survey Invite"),
      content: SizedBox(
        width: 400, // smaller than screen width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _sendSurveyInvite,
                icon: const Icon(Icons.send),
                label: const Text("Send Invite"),
              ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(color: _message!.startsWith('Failed') ? Colors.red : Colors.green),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // closes the popup
          child: const Text('Close'),
        ),
      ],
    );
  }
}
