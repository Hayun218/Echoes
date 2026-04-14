import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text(
              'Your profile and saved story history are coming soon. Use the Home tab to begin a new session, and Story to continue.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
