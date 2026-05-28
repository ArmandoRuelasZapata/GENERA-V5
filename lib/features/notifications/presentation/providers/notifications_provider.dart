import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theoriginallab_v2/features/notifications/domain/notification_model.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

const _kStorageKey = 'app_notifications_v1';
const _kMaxStored = 50; // máximo de notificaciones guardadas

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  final SharedPreferences _prefs;

  NotificationsNotifier(this._prefs) : super([]) {
    _loadFromStorage();
  }

  // ── Carga ────────────────────────────────────────────────

  void _loadFromStorage() {
    try {
      final raw = _prefs.getString(_kStorageKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {
      // Si los datos están corruptos, empezar limpio
      _prefs.remove(_kStorageKey);
    }
  }

  // ── Persistencia ─────────────────────────────────────────

  Future<void> _save() async {
    try {
      final json = jsonEncode(state.map((n) => n.toJson()).toList());
      await _prefs.setString(_kStorageKey, json);
    } catch (_) {
      // Si falla al guardar, no bloqueamos la UI
    }
  }

  // ── API pública ──────────────────────────────────────────

  /// Inserta al inicio (más reciente primero). Ignora duplicados por [id].
  void addNotification(NotificationModel notification) {
    final alreadyExists = state.any((n) => n.id == notification.id);
    if (alreadyExists) return;
    // Limitar a _kMaxStored para no crecer indefinidamente
    final updated = [notification, ...state];
    state = updated.length > _kMaxStored
        ? updated.sublist(0, _kMaxStored)
        : updated;
    _save();
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
    _save();
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
    _save();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _prefs.remove(_kStorageKey);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationsNotifier(prefs);
  },
);

/// Número de notificaciones no leídas (badge en AppBar).
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
