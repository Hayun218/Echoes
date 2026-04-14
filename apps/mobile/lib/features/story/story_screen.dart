import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';

class StoryScreen extends StatefulWidget {
  final String? sessionId;
  final String? sceneTitle;

  const StoryScreen({super.key, this.sessionId, this.sceneTitle});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (widget.sessionId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _messages = await ApiClient.fetchSessionMessages(widget.sessionId!);
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
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

  Future<void> _sendTurn() async {
    if (widget.sessionId == null || _controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ApiClient.addSessionTurn(sessionId: widget.sessionId!, userInput: _controller.text.trim());
      _controller.clear();
      await _loadMessages();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Start a story from Home to see your session here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Text(
              widget.sceneTitle ?? 'Story session',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No story turns yet. Submit your first line to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message.senderType == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.deepPurple : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUser ? 'You' : 'Echoes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isUser ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Continue the scene...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTurn(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendTurn,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
                  child: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
