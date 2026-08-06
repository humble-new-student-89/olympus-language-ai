# Olympus Language AI — History

## Version History

- **1.0.0-phase4** (`2026-08-06`): Phase 4 complete — In-flow correction extraction via LLM JSON mode. AI responses now return structured `{response, correction}` with corrections displayed as orange chips inline during conversation, in recap, and in session history. Adaptive difficulty: fluency level (Beginner→Fluent) injected into LLM system prompt so vocabulary and sentence complexity auto-adjust per learner. TTS speaks only the response text; corrections are visual-only.
- **1.0.0-phase3** (`2026-08-06`): Phase 3 complete — Free trial metering (10 min), daily streak tracking with 48h grace period, fluency scoring algorithm (local, no AI call), shareable milestones (sessions/streaks/minutes), progress dashboard with fl_chart trend line, Android Billing Library integration via `in_app_purchase`, paywall screen with Free/Core/Unlimited tiers, FCM push notifications for streak reminders, usage guard preventing free tier overage. Extended Firestore with milestones, fcmTokens, fluency fields, subscription tracking.
- **1.0.0-phase2** (`2026-08-06`): Phase 2 complete — Scenario picker (6 predefined scenarios with custom system prompts), post-session recap screen (AI-generated mistake analysis + strengths), session history screen (list + transcript detail + recap summary), extended Firestore schema with scenarioName/topMistakes/strength fields.
- **1.0.0-phase1** (`2026-08-06`): Phase 1 complete — Flutter project scaffold, Firebase integration (auth + Firestore), voice pipeline (Deepgram STT + OpenRouter LLM + Deepgram TTS), walkie-talkie conversation screen, GoRouter navigation with auth guards.
- **0.1.0** (`2026-08-06`): Initial project creation, requirements doc.
