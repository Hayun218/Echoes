import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String sessionId, String sceneTitle) onSessionStarted;

  const HomeScreen({super.key, required this.onSessionStarted});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _startStory() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.startSession(concept: _controller.text.trim());
      widget.onSessionStarted(result.sessionId, result.sceneTitle);
      _controller.clear();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Home',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'One-line concept',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Describe the story moment in one line',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _startStory(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startStory,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Start story'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            const Text(
              'Your latest stories will appear under Story once you start a session.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tip',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a clear concept with a scene or feeling: "A quiet temple with a hidden promise."',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
