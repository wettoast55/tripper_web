import 'package:flutter/material.dart';

class SendSurveyPage extends StatefulWidget {
  const SendSurveyPage({super.key});

  @override
  State<SendSurveyPage> createState() => _SendSurveyPageState();
}

class _SendSurveyPageState extends State<SendSurveyPage> {

  // Controller for the email input field
  final _emailController = TextEditingController();
  final List<String> _emails = [];

  // Function to add email to the list
  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_emails.contains(email)) {
      setState(() {
        _emails.add(email);
        _emailController.clear();
      });
    }
  }
  
  // Function to send survey invites
  void _sendInvites() {

    // TODO: Replace this with actual email/send logic
    print("Sending survey to: $_emails");

    // Show a confirmation message after emails are sent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Survey sent to: ${_emails.join(", ")}')),
    );
  }

  // Build method to render the UI
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _emailController,

            // Attach the focus node to textfield so messages
            decoration: InputDecoration(
              labelText: 'Enter email to invite',
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: _addEmail,
              ),
            ),
            onSubmitted: (_) => _addEmail(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _emails.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(_emails[i]),
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.send),
            label: Text("Send Survey"),
            onPressed: _emails.isEmpty ? null : _sendInvites,
          ),
        ],
      ),
    );
  }
}
