# Olympus Language AI — AI Model Evidence

Generated: `2026-08-06`

## Detected Models

- **OpenRouter `openai/gpt-4o-mini`** — primary reasoning/correction LLM via OpenRouter API.
- **Deepgram Nova-3** — speech-to-text (STT) model.
- **Deepgram Aura (`aura-asteria-en`)** — text-to-speech (TTS) model.

Confidence: `high`

## Evidence

- `lib/core/voice/openrouter_service.dart` — POSTs to `https://openrouter.ai/api/v1/chat/completions` with model `openai/gpt-4o-mini`.
- `lib/core/voice/deepgram_stt_service.dart` — POSTs to `https://api.deepgram.com/v1/listen?model=nova-3`.
- `lib/core/voice/deepgram_tts_service.dart` — POSTs to `https://api.deepgram.com/v1/speak?model=aura-asteria-en`.
- System prompt in OpenRouterService configures it as a patient language tutor.

## Co-Authors / Other Models

- `Claude Code` / `CommandCodeBot` — initial project scaffold and Phase 1 implementation.

## Methodology

Determined from source code analysis of voice service files in `lib/core/voice/`.
