# Olympus Language AI

**Bundle ID:** `com.tutivsoft.olympuslanguageai`

[![CI](https://github.com/humble-new-student-89/olympus-language-ai/actions/workflows/ci.yml/badge.svg)](https://github.com/humble-new-student-89/olympus-language-ai/actions/workflows/ci.yml)

Voice-first language learning app built with Flutter. Speak with a patient AI partner that corrects you in the moment.

## Status

**Phase 5 — Testing & Production Readiness** (87 tests, zero analysis issues)

## Quick Start

```bash
flutter pub get
flutter run
```

Requires `.env` file with `DEEPGRAM_API_KEY`, `OPENROUTER_API_KEY`, and Firebase config in `android/app/google-services.json`.

## Testing

```bash
flutter test          # 87 unit + widget tests
flutter analyze       # zero issues
flutter build apk     # production build
```

## Architecture

See [architecture.md](architecture.md) for full design docs.

## License

Private — all rights reserved.
