import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../conversation/presentation/providers.dart';
import 'progress_notifier.dart';

final progressStateProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(
    firestore: ref.watch(firestoreServiceProvider),
    streakService: ref.watch(streakServiceProvider),
    fluencyService: ref.watch(fluencyServiceProvider),
  );
});
