import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/my/my_screen.dart';
import '../features/story/story_screen.dart';

class EchoesApp extends StatefulWidget {
  const EchoesApp({super.key});

  @override
  State<EchoesApp> createState() => _EchoesAppState();
}

class _EchoesAppState extends State<EchoesApp> {
  int _selectedIndex = 0;
  String? _activeSessionId;
  String? _activeSceneTitle;

  void _onSessionStarted(String sessionId, String sceneTitle) {
    setState(() {
      _activeSessionId = sessionId;
      _activeSceneTitle = sceneTitle;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onSessionStarted: _onSessionStarted),
      const ExploreScreen(),
      StoryScreen(sessionId: _activeSessionId, sceneTitle: _activeSceneTitle),
      const MyScreen(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Echoes',
      theme: appTheme,
      home: Scaffold(
        body: screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Story'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My'),
          ],
        ),
      ),
    );
  }
}
