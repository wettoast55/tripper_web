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

  // add survey fields
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _travelStyle;

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
  void _sendSurveyInvites() {

    // TODO: Replace this with actual email/send logic
    print("Sending survey to: $_emails");

    // .....
    final destination = _destinationController.text.trim();
    final budget = _budgetController.text.trim();
    final style = _travelStyle ?? "Not selected";

    // .....
    if (destination.isEmpty || budget.isEmpty || _emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill out survey and add at least one email.")),
      );
      return;
    }

    // Simulate sending email
    for (final email in _emails) {
      print("📧 Sending survey to $email");
      print("Destination: $destination, Budget: $budget, Style: $style");
      // TODO: Call backend API to actually send email
    }

    // Show a confirmation message after emails are sent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Survey sent to: ${_emails.join(", ")}')),
    );

    // clears after flow
    setState(() {
      _emails.clear();
    });
  }

  // Build method to render the UI
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // formally Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        
        // MainAxisAlignment to center the content
        crossAxisAlignment: CrossAxisAlignment.start,
          
        children: [
          
          // formatting survey and prettying
          const Text("📝 Survey", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // ****************************************//

          // text field for destination input
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'where might you want to go?',
              border: OutlineInputBorder(),
            ),
          ),

          // text field for max budget estimate
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'how much are you willing to spend?',
              border: OutlineInputBorder(),
            ),

            // looking for int input
            keyboardType: TextInputType.number,
          ),

          // dropdown field for trip vibe type
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value:_travelStyle,
            onChanged:(value) => setState(() => _travelStyle=value),
            decoration: const InputDecoration(
              labelText: 'pick the trip vibe',
              border: OutlineInputBorder(),
            ),

            // item list and corresponding text
            items: const [
              DropdownMenuItem(value : 'Relaxed', child : Text('Relaxed')),
              DropdownMenuItem(value : 'Adventurous', child : Text('Adventurous')),
              DropdownMenuItem(value : 'funsies', child : Text('funsies')),
              DropdownMenuItem(value : 'lit', child : Text('lit')),
            ],
          ),

          // email input section setup
          const SizedBox(height: 24),
          const Divider(),
          const Text("📬 Invite by Email", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          
          // text field for email input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Enter email address to invite someone',
                    border: OutlineInputBorder(),
                  ),

                  // get input and add
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _addEmail(),
                ),
              ),

              // formatting email send box
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addEmail,
              ),
            ],
          ),

          // // text field for email input
          // TextField(
          //   controller: _emailController,

          //   // Attach the focus node to textfield so messages
          //   decoration: InputDecoration(
          //     labelText: 'Enter email to invite',
          //     suffixIcon: IconButton(
          //       icon: Icon(Icons.add),
          //       onPressed: _addEmail,
          //     ),
          //   ),
          //   onSubmitted: (_) => _addEmail(),
          // ),

          // Remove email from list if X chip button clicked
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _emails
                .map((e) => Chip(
                      label: Text(e),
                      onDeleted: () {
                        setState(() {
                          _emails.remove(e);
                        });
                      },
                    ))
                .toList(),
          ),

          // send icon action
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _sendSurveyInvites,
            icon: const Icon(Icons.send),
            label: const Text("Send Survey Invites"),
          ),


          // const SizedBox(height: 16),
          // Expanded(
          //   child: ListView.builder(
          //     itemCount: _emails.length,
          //     itemBuilder: (_, i) => ListTile(
          //       title: Text(_emails[i]),
          //     ),
          //   ),
          // ),
          // ElevatedButton.icon(
          //   icon: Icon(Icons.send),
          //   label: Text("Send Survey"),
          //   onPressed: _emails.isEmpty ? null : _sendInvites,
          // ),
        ],
      ),
    );
  }
}
