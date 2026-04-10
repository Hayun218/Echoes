-- Initial Seed Data for Echoes
-- Inserts initial characters, canonical scenes, and scene participants for the story-oriented launch

-- Characters
INSERT INTO characters (id, slug, name, description, avatar_url, category, tags, sort_order, is_active, is_featured) VALUES
(gen_random_uuid(), 'david', 'David', 'King David, the psalmist and shepherd-king whose life spans joy, struggle, and faith.', 'https://example.com/david-avatar.jpg', 'Old Testament', '["warrior", "poet", "king"]', 1, true, true),
(gen_random_uuid(), 'esther', 'Esther', 'Queen Esther, courageous and wise, who stepped into a dangerous palace story to save her people.', 'https://example.com/esther-avatar.jpg', 'Old Testament', '["queen", "courage", "heart"]', 2, true, true),
(gen_random_uuid(), 'paul', 'Paul', 'Apostle Paul, the missionary thinker whose journeys shaped the early church narrative.', 'https://example.com/paul-avatar.jpg', 'New Testament', '["apostle", "missionary", "teacher"]', 3, true, true);

-- Canonical scenes for David
INSERT INTO scenes (id, character_id, slug, title, description, intro_text, prompt_template, thumbnail_url, mood_tags, difficulty_level, access_tier, is_public_browse, is_active, sort_order) VALUES
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'david'), 'david-shepherds-heart', 'Shepherd''s Heart', 'Enter a pastoral scene with David before kingship, where faith and leadership begin to take shape.', 'Begin with David in the fields, listening to the land and the Lord, and choose how his heart responds.', 'You are David, a young shepherd called to faithfulness. Describe your care for the flock and the inward courage you need.', 'https://example.com/david-shepherds-heart.jpg', '["pastoral", "faithful", "introductory"]', 2, 'free', true, true, 1),
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'david'), 'david-kingdoms-rise', 'Kingdoms Rise', 'Experience the moment David must balance loyalty, power, and mercy as a new king.', 'Step into the royal court and weigh hard choices with David as his story becomes a national legend.', 'You are King David, older and wiser. Speak with humility about leadership, loyalty, and the cost of victory.', 'https://example.com/david-kingdoms-rise.jpg', '["political", "reflective", "dramatic"]', 4, 'premium', false, true, 2);

-- Canonical scenes for Esther
INSERT INTO scenes (id, character_id, slug, title, description, intro_text, prompt_template, thumbnail_url, mood_tags, difficulty_level, access_tier, is_public_browse, is_active, sort_order) VALUES
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'esther'), 'esther-palace-entrance', 'Palace Entrance', 'Join Esther as she enters the royal court and learns to navigate influence and identity.', 'Begin in the palace halls and choose how Esther prepares to use her voice for her people.', 'You are Esther, attentive and faithful. Describe your observations and the quiet courage growing inside you.', 'https://example.com/esther-palace-entrance.jpg', '["royal", "tactical", "hopeful"]', 2, 'free', true, true, 1),
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'esther'), 'esther-king-supper', 'The King''s Supper', 'Relive the tense moment Esther invites the king and his guard, with the fate of her people hanging in the balance.', 'You are Esther, poised and prayerful. Decide how much to reveal and how to draw strength from your faith.', 'You are Esther, wise and brave. Frame your words with both grace and urgency.', 'https://example.com/esther-kings-supper.jpg', '["tense", "courageous", "strategic"]', 4, 'premium', false, true, 2);

-- Canonical scenes for Paul
INSERT INTO scenes (id, character_id, slug, title, description, intro_text, prompt_template, thumbnail_url, mood_tags, difficulty_level, access_tier, is_public_browse, is_active, sort_order) VALUES
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'paul'), 'paul-road-tarshish', 'Road to Tarshish', 'Begin Paul''s story before conversion, with a mission shaped by zeal and a world still waiting for grace.', 'Start with Paul on the road, driven by conviction and unaware of the shift that is about to come.', 'You are Paul before the road changed. Explain your passion, your fears, and what would need to shift to see a new purpose.', 'https://example.com/paul-road-tarshish.jpg', '["journey", "searching", "dramatic"]', 3, 'free', true, true, 1),
(gen_random_uuid(), (SELECT id FROM characters WHERE slug = 'paul'), 'paul-athens-debate', 'Athens Debate', 'Join Paul as he engages diverse thinkers in the marketplace of ideas, defending a new gospel.', 'Enter the Agora with Paul and craft your response to curious seekers and skeptical philosophers.', 'You are Paul, articulate and bold. Speak with conviction about faith, reason, and the city''s soul.', 'https://example.com/paul-athens-debate.jpg', '["philosophical", "debate", "inspiring"]', 5, 'premium', false, true, 2);

-- Scene participants for multi-character moments
INSERT INTO scene_participants (id, scene_id, character_id, role_in_scene, sort_order, is_active) VALUES
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'david-kingdoms-rise'), (SELECT id FROM characters WHERE slug = 'esther'), 'advisor', 1, true),
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'david-kingdoms-rise'), (SELECT id FROM characters WHERE slug = 'paul'), 'messenger', 2, true),
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'esther-kings-supper'), (SELECT id FROM characters WHERE slug = 'david'), 'royal ally', 1, true),
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'esther-kings-supper'), (SELECT id FROM characters WHERE slug = 'paul'), 'observer', 2, true),
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'paul-athens-debate'), (SELECT id FROM characters WHERE slug = 'esther'), 'listener', 1, true),
(gen_random_uuid(), (SELECT id FROM scenes WHERE slug = 'paul-athens-debate'), (SELECT id FROM characters WHERE slug = 'david'), 'historical echo', 2, true);