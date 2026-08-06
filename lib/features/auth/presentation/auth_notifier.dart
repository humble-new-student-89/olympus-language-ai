import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_state.dart';
import '../data/auth_repository.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthLoading()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    });
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = AuthLoading();
    try {
      final user = await _repository.signUp(email, password);
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _repository.signIn(email, password);
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthUnauthenticated();
  }
}
