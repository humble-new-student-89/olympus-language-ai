# COMMANDCODE Memory — Olympus Language AI

## Project Info
- **Bundle ID**: `com.tutivsoft.olympuslanguageai`
- **Firebase Project**: `olympus-language-ai` (82086094583)
- **Google Services**: `android/app/google-services.json`
- **Platform**: Android (MVP), Flutter 3.x
- **API Keys**: `.env` (gitignored) + `openrouter_api_key.txt`

## Key Reference
- **Requirements**: `requirements.md`
- **Implementation Plan**: Phase 1 complete (foundation + voice pipeline)
- **Voice Pipeline**: Deepgram Nova-3 (STT) → OpenRouter (LLM) → Deepgram Aura (TTS)
- **Auth**: Firebase Auth (email/password + Google Sign-In)
- **Database**: Firestore (users, sessions, transcripts)
