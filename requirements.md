# AI Speaking Partner — High-Level Requirements

## One-liner
A voice-first app that lets language learners have real, spoken conversations with a patient AI partner that corrects them in the moment — the "speaking practice" wedge, not another course.

## Target User
Intermediate+ learners who already know grammar/vocab but freeze up speaking. They currently pay for apps (Duolingo/Babbel) AND human tutors (iTalki/Preply) but have no cheap, always-available way to just *talk*.

## Why Now
Low-latency voice models made real-time spoken correction cheap enough to sell as a $10–20/mo subscription instead of a $20/hr tutor session.

## Stack Notes
- Flutter (iOS/Android/Web from one codebase)
- OpenRouter for the reasoning/correction LLM
- Need a dedicated low-latency STT + TTS (or realtime voice) provider alongside OpenRouter — OpenRouter itself doesn't do speech; treat this as a separate integration
- Backend: auth, subscription/billing, usage metering, conversation history storage

---

## MVP Features — Core Conversation Experience (Top 5)

1. **One-tap live voice conversation**
   Open app → talking within 2 seconds. No menus before the first word. This *is* the product.

2. **In-flow gentle correction**
   AI keeps the conversation moving but flags mistakes lightly (tone/grammar/word choice) without breaking immersion — correct, don't lecture.

3. **Scenario/role picker**
   Pre-built situations (job interview, ordering food, small talk, dating, doctor visit) so practice feels purposeful, not open-ended and awkward.

4. **Adaptive difficulty**
   AI adjusts vocabulary/speaking speed to the learner's level automatically and nudges it up as they improve — so it stays useful for months, not weeks.

5. **Post-session recap**
   After each call: short transcript, top 3 mistakes, one thing they did well. Turns a fleeting conversation into visible learning.

---

## MVP Features — Retention & Monetization (Top 5)

1. **Free trial minutes, then metered/subscription paywall**
   Give enough free talk-time to feel the "aha," then convert (e.g., 10 free min → $12–20/mo for X min or unlimited).

2. **Daily streak + smart reminders**
   Push notification when they're about to break a streak or haven't spoken in 2 days — habit is the product's real moat.

3. **Fluency score over time**
   A single trackable number/graph (accuracy, fluency, vocab range) updated each session — gives the subscriber a reason to see "am I improving" and justify renewal.

4. **Session history & shareable wins**
   Saved transcripts + corrections library learners can revisit; occasional shareable milestone ("50 conversations completed") drives organic growth.

5. **Tiered plans by usage, not features**
   Free (trial minutes) → Core (capped minutes/mo) → Unlimited — keep feature set identical across tiers so the upsell is purely "talk more," which is the core value, not a paywalled feature maze.

---

## Explicitly Out of Scope for MVP
- Grammar/vocab courses, flashcards, gamified lessons (crowded, not the wedge)
- Group conversations / community features
- Multiple AI personalities/voices (pick one good one first)
- Text chat mode (voice is the differentiator — don't dilute it)

## Success Metric for MVP
% of trial users who convert to paid **and** are still doing ≥3 conversations/week at day 30. If retention on that number is weak, the correction/scenario quality — not pricing — is the problem to fix first.

---

## Technical Decisions to Lock In

1. **STT/TTS provider** — Deepgram, ElevenLabs, or Azure Speech. This is the latency bottleneck. Pick one.
2. **Auth & Database** — Firebase Auth (email/password + Google sign-in) + Firestore for users, sessions, transcripts, corrections, streaks, usage minutes.
3. **Platform** — Android only for MVP. iOS and web later.
4. **Billing** — Deferred. No payments in MVP. Add Stripe + RevenueCat later.
5. **Hosting** — Firebase handles everything (auth, DB, cloud functions if needed). No separate backend for now.

## Open Design Questions

1. **Correction flow** — Does the AI weave corrections naturally into its next response ("Actually, it's 'went' not 'goed'. So you went to the park..."), or pause the flow and explicitly call it out? Natural is better for immersion but harder to prompt reliably.
2. **Conversation mode** — Walkie-talkie (speak → wait → hear) or true duplex (interrupt anytime)? Walkie-talkie is simpler to build and good enough for MVP.
3. **Talk-time metering** — Count from STT start to TTS end per turn? Or just wall-clock session duration? Wall-clock is simpler but less fair.
