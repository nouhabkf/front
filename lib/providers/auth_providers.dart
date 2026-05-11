import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/user_session_cache.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import 'api_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient: apiClient);
});

/// Fournit l'état d'authentification : connecté avec User ou non.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthStateNotifier(authRepo, userRepo);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthStateNotifier(this._authRepo, this._userRepo)
      : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  static const Duration _checkAuthTimeout = Duration(seconds: 8);

  Future<void> _checkAuth() async {
    final hasToken = await _authRepo.hasStoredToken();
    if (!hasToken) {
      await UserSessionCache.clear();
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final user = await _userRepo.getMe().timeout(
        _checkAuthTimeout,
        onTimeout: () {
          throw Exception('timeout');
        },
      );
      await UserSessionCache.save(user);
      state = AsyncValue.data(user);
    } catch (e, _) {
      if (_isUnauthorized(e)) {
        await _authRepo.logout();
        await UserSessionCache.clear();
        state = const AsyncValue.data(null);
        return;
      }
      final cached = await UserSessionCache.read();
      if (cached != null) {
        state = AsyncValue.data(cached);
        return;
      }
      await _authRepo.logout();
      state = const AsyncValue.data(null);
    }
  }

  bool _isUnauthorized(Object e) {
    if (e is DioException) {
      final c = e.response?.statusCode;
      return c == 401 || c == 403;
    }
    return false;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _authRepo.login(email: email, password: password);
      await UserSessionCache.save(auth.user);
      state = AsyncValue.data(auth.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _authRepo.loginWithGoogle(idToken: idToken);
      await UserSessionCache.save(auth.user);
      state = AsyncValue.data(auth.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    await UserSessionCache.clear();
    state = const AsyncValue.data(null);
  }

  void setUser(UserModel? user) {
    state = AsyncValue.data(user);
    if (user != null) {
      unawaited(UserSessionCache.save(user));
    } else {
      unawaited(UserSessionCache.clear());
    }
  }

  /// Rafraîchit l'utilisateur courant (après PATCH profil, etc.).
  Future<void> refreshUser() async {
    try {
      final user = await _userRepo.getMe();
      await UserSessionCache.save(user);
      state = AsyncValue.data(user);
    } catch (e) {
      if (_isUnauthorized(e)) {
        await _authRepo.logout();
        await UserSessionCache.clear();
        state = const AsyncValue.data(null);
      }
    }
  }
}
