import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

const _apiBaseUrl = String.fromEnvironment(
  'ECHOES_API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
const _profileHeader = 'X-Profile-Id';
const _profileId = '00000000-0000-0000-0000-000000000001';

class ApiClient {
  const ApiClient._();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        _profileHeader: _profileId,
      };

  static Future<List<SceneSummary>> fetchScenes() async {
    final uri = Uri.parse('$_apiBaseUrl/scenes');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load scenes');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => SceneSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<SceneDetail> fetchSceneDetail(String sceneId) async {
    final uri = Uri.parse('$_apiBaseUrl/scenes/$sceneId');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load scene details');
    }
    return SceneDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<Character>> fetchCharacters() async {
    final uri = Uri.parse('$_apiBaseUrl/characters');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load characters');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Character.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<SessionStartResult> startSession({
    required String concept,
    String? sceneId,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/sessions/start');
    final body = {
      'concept': concept,
      if (sceneId != null) 'scene_id': sceneId,
    };
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception('Failed to start session');
    }
    return SessionStartResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<Message>> fetchSessionMessages(String sessionId) async {
    final uri = Uri.parse('$_apiBaseUrl/sessions/$sessionId/messages');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load session messages');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<void> addSessionTurn({
    required String sessionId,
    required String userInput,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/sessions/$sessionId/turns');
    final body = {
      'user_input': userInput,
    };
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception('Failed to add story turn');
    }
  }
}
