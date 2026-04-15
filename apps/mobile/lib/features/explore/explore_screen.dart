import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import 'scene_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final Future<void> _loadFuture;
  List<SceneSummary> _scenes = [];
  List<Character> _characters = [];

  Future<void> _loadData() async {
    final scenes = await ApiClient.fetchScenes();
    final characters = await ApiClient.fetchCharacters();
    _scenes = scenes;
    _characters = characters;
  }

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Unable to load explore content',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadFuture = _loadData();
                });
                await _loadFuture;
              },
              child: ListView(
                children: [
                  const Text('Explore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Scenes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._scenes.map((scene) => _SceneCard(scene: scene)).toList(),
                  const SizedBox(height: 24),
                  const Text('Characters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._characters.map((character) => _CharacterTile(character: character)).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final SceneSummary scene;

  const _SceneCard({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SceneDetailScreen(sceneId: scene.id),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scene.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(scene.description, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(scene.character.name, style: const TextStyle(color: Colors.black87)),
                  Chip(label: Text(scene.accessTier.toUpperCase())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  final Character character;

  const _CharacterTile({required this.character});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(character.name),
        subtitle: Text(character.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
