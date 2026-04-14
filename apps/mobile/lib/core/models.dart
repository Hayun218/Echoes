class Character {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String? avatarUrl;
  final String? category;
  final List<String> tags;

  Character({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    this.avatarUrl,
    this.category,
    required this.tags,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatar_url'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class CharacterSummary {
  final String id;
  final String slug;
  final String name;

  CharacterSummary({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory CharacterSummary.fromJson(Map<String, dynamic> json) {
    return CharacterSummary(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
    );
  }
}

class SceneSummary {
  final String id;
  final String title;
  final String description;
  final String introText;
  final String accessTier;
  final CharacterSummary character;

  SceneSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.introText,
    required this.accessTier,
    required this.character,
  });

  factory SceneSummary.fromJson(Map<String, dynamic> json) {
    return SceneSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      introText: json['intro_text'] as String,
      accessTier: json['access_tier'] as String,
      character: CharacterSummary.fromJson(json['character'] as Map<String, dynamic>),
    );
  }
}

class SceneDetail extends SceneSummary {
  final String promptTemplate;
  final List<String> moodTags;
  final String? thumbnailUrl;
  final int difficultyLevel;

  SceneDetail({
    required String id,
    required String title,
    required String description,
    required String introText,
    required String accessTier,
    required CharacterSummary character,
    required this.promptTemplate,
    required this.moodTags,
    this.thumbnailUrl,
    required this.difficultyLevel,
  }) : super(
          id: id,
          title: title,
          description: description,
          introText: introText,
          accessTier: accessTier,
          character: character,
        );

  factory SceneDetail.fromJson(Map<String, dynamic> json) {
    return SceneDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      introText: json['intro_text'] as String,
      accessTier: json['access_tier'] as String,
      character: CharacterSummary.fromJson(json['character'] as Map<String, dynamic>),
      promptTemplate: json['prompt_template'] as String,
      moodTags: (json['mood_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbnailUrl: json['thumbnail_url'] as String?,
      difficultyLevel: json['difficulty_level'] as int,
    );
  }
}

class Message {
  final String id;
  final String sessionId;
  final String senderType;
  final String speakerType;
  final String? speakerCharacterId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.sessionId,
    required this.senderType,
    required this.speakerType,
    this.speakerCharacterId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      senderType: json['sender_type'] as String,
      speakerType: json['speaker_type'] as String,
      speakerCharacterId: json['speaker_character_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SessionStartResult {
  final String sessionId;
  final String sceneId;
  final String sceneTitle;

  SessionStartResult({
    required this.sessionId,
    required this.sceneId,
    required this.sceneTitle,
  });

  factory SessionStartResult.fromJson(Map<String, dynamic> json) {
    return SessionStartResult(
      sessionId: json['session_id'] as String,
      sceneId: json['scene']['id'] as String,
      sceneTitle: json['scene']['title'] as String,
    );
  }
}
