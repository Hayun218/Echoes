import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';

class SceneDetailScreen extends StatefulWidget {
  final String sceneId;

  const SceneDetailScreen({super.key, required this.sceneId});

  @override
  State<SceneDetailScreen> createState() => _SceneDetailScreenState();
}

class _SceneDetailScreenState extends State<SceneDetailScreen> {
  late Future<SceneDetail> _sceneFuture;

  @override
  void initState() {
    super.initState();
    _sceneFuture = ApiClient.fetchSceneDetail(widget.sceneId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scene details')),
      body: FutureBuilder<SceneDetail>(
        future: _sceneFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load scene: ${snapshot.error}'));
          }
          final scene = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Text(scene.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Chip(label: Text(scene.accessTier.toUpperCase())),
                const SizedBox(height: 18),
                Text(scene.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 18),
                const Text('Intro', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(scene.introText, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 18),
                const Text('Character', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(scene.character.name, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 14),
                const Text('Mood tags', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: scene.moodTags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
                const SizedBox(height: 18),
                const Text('Prompt template', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(scene.promptTemplate, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          );
        },
      ),
    );
  }
}
