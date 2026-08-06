# Changelog

## 1.0.0-phase1 - 2026-08-06

- Flutter Android project scaffold (bundle: `com.tutivsoft.olympuslanguageai`)
- Firebase integration: Auth (email/password + Google Sign-In), Firestore (users/sessions/transcripts)
- Voice pipeline: Deepgram Nova-3 STT → OpenRouter GPT-4o-mini → Deepgram Aura TTS
- Walkie-talkie conversation mode with press-and-hold mic
- Animated state indicator (idle, recording, processing, speaking, error)
- GoRouter navigation with auth guards (login/signup/home/conversation)
- Riverpod state management throughout
- `flutter analyze`: 0 issues
