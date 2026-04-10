# Echoes Product Planning

This document defines the next product-planning layer for Echoes, focusing on access policy, story depth, and the scene model. It is intended to guide the next schema revision and API design.

## 1. Access & Tier Policy

### Public Browse
- Users can discover scene metadata and character teasers without signing in.
- Public browse shows only scenes with `is_public_browse = true` and sanitized preview content.
- Public browse is a discovery dimension separate from free/premium access; it controls visibility, not paid entitlement.
- Public visitors cannot create sessions, save progress, or send user input to story flows.
- Public browse supports marketing, discovery, and initial engagement to convert users.

### Logged-in Free
- Authenticated free users can start sessions for free scenes and selected public scenes.
- Free users can save story progress and resume sessions within limits.
- Free access includes a short but complete story experience that demonstrates core Echoes value.
- Free scenes deliver concise narrative arcs with enough closure to feel satisfying while leaving premium depth gated.
- Free users get access to a baseline reflection layer and limited generative scene content.

### Premium
- Premium users unlock premium scenes, richer participant interactions, and deeper narrative continuity.
- Premium sessions may include additional generative branches, multi-scene arcs, and advanced reflection features.
- Premium entitlement supports a single active paid subscription per profile and premium-only scene gating.
- Premium access enables unlimited or higher quota usage tracking through `usage_counters`.    

## 2. Story Depth Model

### Free User Experience
- Free users experience a compact story arc with one or two scene turns and shallow branching.
- Scenes remain engaging but are designed for quick completion and easy replay.
- Participants are limited to core characters and straightforward story roles.
- Continuity is preserved within a single session using `progression_state`, but cross-session arcs are simpler.
- Reflection prompts are basic: users see summary feedback and one reflective question or insight.

### Premium User Unlocks
- Premium users access multi-stage story arcs, deeper participant interplay, and richer branching.
- Premium scenes can include multiple characters, scene participants, and more complex roles.
- Continuity extends across sessions and scenes through session-level `story_metadata` and `progression_state`.
- Premium reflection includes layered insights, scene debriefs, and optional next-step suggestions.
- Generative story sessions can be more adaptive, with premium prompts using additional metadata.

### Differences in Depth and Continuity
- `access_tier` distinguishes free vs premium scenes.
- Free scenes may use a simpler `prompt_template`; premium scenes may embed richer generative metadata.
- Participant count and role complexity increase in premium content.
- Continuity for free users is session-scoped; premium users can retain more complex narrative state across sessions.
- Reflection for premium users can include analytical or thematic commentary beyond basic story recap.

## 3. Scene Model

### Canonical Scene
- A canonical scene is a biblically anchored story segment with controlled narrative boundaries.
- It uses `scenes.character_id` as the primary character and `scene_participants` for additional actors.
- Canonical scenes are designed with curated themes, participant roles, and contained plot structure.
- These scenes contain metadata: title, description, intro_text, mood_tags, access_tier, `is_public_browse`, and `prompt_template`.
- Canonical scenes are the foundation for free and premium content where structure and quality are controlled.

### Generative Scene
- A generative scene is a narrative experience that adapts at runtime through session-level state.
- It is anchored by a scene record but variation is driven mainly through `sessions.story_metadata` and `sessions.progression_state`.
- Generative scenes can be either free or premium depending on gating, while preserving narrative coherence.
- Runtime variation is managed in the session, ensuring each user story remains consistent and resumable.

### Participants
- `scenes.character_id` remains the primary character for the scene.
- `scene_participants` defines all other characters in the scene with `role_in_scene`, `sort_order`, and `is_active`.
- Premium content increases participant complexity and multi-character interplay as a differentiator.
- Premium scenes should support richer role dynamics, multi-speaker turns, and more active scene participant choreography.
- The API should expose participant lists for scene setup and speaker routing.

### Narrative Progression
- Progression state belongs in `sessions.progression_state` and is the primary source of story continuity.
- On session creation, the story orchestration layer initializes state and participant context.
- Each message turn updates `progression_state` with user choices, branch identifiers, and current narrative position.
- The story progression service should compute next scene actions, participant turns, and possible reflection points.

### Reflection Layer
- The reflection layer provides story-aware recap, insight, and optional next-step prompts.
- Basic reflection is available to free users, while premium users receive deeper thematic summaries.
- Reflection can be generated at scene end or on demand, using `progression_state` and `story_metadata`.
- This layer should be exposed through a dedicated API endpoint, not mixed directly into raw message traffic.

## Implementation Guidance
- Keep current tables in place; add `scene_participants` and session-level narrative fields as the main schema extension.
- Preserve monetization tables and subscription gating as-is.
- Use session-level state to drive continuity instead of scattering narrative state into scene records.
- Ensure API routes clearly separate scene discovery, session orchestration, message turns, and reflection.
- Prioritize the user-facing story model over chat jargon when naming new endpoints and services.
