import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
part 'auth_provider.freezed.dart';

// Estado de autenticación
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

// Configuración del timeout de inactividad (OWASP M3)
const _kInactivityTimeout = Duration(minutes: 15);

// Notifier
class AuthNotifier extends StateNotifier<AuthState>
    with WidgetsBindingObserver {
  final AuthRepository _repository;
  Timer? _inactivityTimer;

  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    WidgetsBinding.instance.addObserver(this);
    checkAuthStatus();
  }

  /// Reinicia el contador de inactividad.
  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (state is _Authenticated) {
      _repository.saveLastActivity();
      _inactivityTimer = Timer(_kInactivityTimeout, () {
        logout();
      });
    }
  }

  /// Comprueba si ha pasado el tiempo de inactividad permitido.
  Future<void> _checkInactivity() async {
    if (state is! _Authenticated) return;

    final lastActivity = await _repository.getLastActivity();
    if (lastActivity == null) {
      await _repository.saveLastActivity();
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final elapsed = now - lastActivity;

    if (elapsed >= _kInactivityTimeout.inMilliseconds) {
      if (kDebugMode) {
        debugPrint('Sesion expirada por inactividad persistente.');
      }
      await logout();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _checkInactivity().then((_) {
        resetInactivityTimer();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    final isLogged = await _repository.isLoggedIn();

    if (isLogged) {
      final result = await _repository.getCurrentUser();

      result.fold(
        (failure) => state = const AuthState.unauthenticated(),
        (user) {
          if (user != null) {
            state = AuthState.authenticated(user);
            _checkInactivity().then((_) {
              resetInactivityTimer();
            });
          } else {
            state = const AuthState.unauthenticated();
          }
        },
      );
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    final result = await _repository.login(email: email, password: password);

    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) {
        state = AuthState.authenticated(user);
        resetInactivityTimer();
      },
    );
  }

  Future<void> register({
    required String email,
    required String name,
    required String password,
    String? phone,
  }) async {
    state = const AuthState.loading();

    final result = await _repository.register(
      email: email,
      name: name,
      password: password,
      phone: phone,
    );

    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) {
        state = const AuthState.unauthenticated();
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  Future<String?> activateAccount({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Completa email y contraseña';
    }

    final result = await _repository.activateAccount(
      email: email,
      password: password,
    );
    return result.fold((failure) => failure.message, (_) => null);
  }

  Future<String?> deactivateAccount(String password) async {
    if (password.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    final result = await _repository.deactivateAccount(password: password);
    return result.fold((failure) => failure.message, (_) => null);
  }

  Future<String?> deleteAccount(String password) async {
    if (password.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    final result = await _repository.deleteAccount(password: password);
    return result.fold((failure) => failure.message, (_) => null);
  }

  // ── Actualiza la foto de perfil en memoria sin re-login ────────────────────
  void updateProfileImage(String imageUrl) {
    state.whenOrNull(
      authenticated: (user) {
        state = AuthState.authenticated(
          user.copyWith(profileImage: imageUrl),
        );
      },
    );
  }
}