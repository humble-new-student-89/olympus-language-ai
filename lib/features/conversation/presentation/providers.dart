import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/voice/voice_pipeline.dart';
import '../../../core/voice/deepgram_stt_service.dart';
import '../../../core/voice/deepgram_tts_service.dart';
import '../../../core/voice/openrouter_service.dart';
import '../../../core/firebase/firestore_service.dart';
import '../../progress/domain/streak_service.dart';
import '../../progress/domain/fluency_service.dart';
import '../../milestones/domain/milestone_service.dart';
import '../domain/conversation_state.dart';
import '../data/conversation_repository.dart';
import 'conversation_notifier.dart';

final sttServiceProvider = Provider<DeepgramSttService>((ref) {
  return DeepgramSttService();
});

final ttsServiceProvider = Provider<DeepgramTtsService>((ref) {
  return DeepgramTtsService();
});

final llmServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

final voicePipelineProvider = Provider<VoicePipeline>((ref) {
  return VoicePipeline(
    stt: ref.watch(sttServiceProvider),
    llm: ref.watch(llmServiceProvider),
    tts: ref.watch(ttsServiceProvider),
  );
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(
    firestore: ref.watch(firestoreServiceProvider),
  );
});

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService();
});

final fluencyServiceProvider = Provider<FluencyService>((ref) {
  return FluencyService();
});

final milestoneServiceProvider = Provider<MilestoneService>((ref) {
  return MilestoneService();
});

final conversationStateProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(
    pipeline: ref.watch(voicePipelineProvider),
    repository: ref.watch(conversationRepositoryProvider),
    firestore: ref.watch(firestoreServiceProvider),
    streakService: ref.watch(streakServiceProvider),
    fluencyService: ref.watch(fluencyServiceProvider),
    milestoneService: ref.watch(milestoneServiceProvider),
  );
});
