import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final sendSurvey = FirebaseFunctions.instance.httpsCallable('sendSurveyEmail');
      final token = DateTime.now().millisecondsSinceEpoch.toString();

      await sendSurvey.call({
        'email': email,
        'token': token,
      });

      setState(() {
        _message = 'Survey invite sent to $email!';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
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
