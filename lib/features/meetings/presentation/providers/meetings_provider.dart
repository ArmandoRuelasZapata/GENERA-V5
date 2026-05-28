import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/booking_webhook_service.dart';
import '../../domain/entities/meeting_request.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/meetings_repository.dart';
import '../../../../shared/providers/providers.dart';

// Repository Provider — uses real webhook with the logged-in user's data
final meetingsRepositoryProvider = Provider<MeetingsRepository>((ref) {
  return ref.watch(meetingsRepositoryDiProvider);
});

final bookingWebhookServiceProvider = Provider<BookingWebhookService>((ref) {
  return ref.watch(bookingWebhookServiceDiProvider);
});

final timeSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DateTime>((ref, date) async {
  final service = ref.watch(bookingWebhookServiceProvider);
  return service.getTimeSlotsForDate(date);
});

// Meetings List Provider con polling cada 30s para mantener la agenda actualizada
// sin depender de pull-to-refresh manual.
final meetingsListProvider = StreamProvider<List<MeetingRequest>>((ref) async* {
  final repository = ref.watch(meetingsRepositoryProvider);

  // Función interna para obtener meetings
  Future<List<MeetingRequest>> fetch() async {
    final result = await repository.getMeetings();
    return result.fold(
      (error) => throw Exception(error),
      (meetings) => meetings,
    );
  }

  // Primera carga inmediata
  yield await fetch();

  // Polling cada 30 segundos
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      yield await fetch();
    } catch (_) {
      // Fallo silencioso en poll — no corta el stream, el valor previo
      // permanece en pantalla.
    }
  }
});

// Create Meeting Notifier
final createMeetingProvider =
    StateNotifierProvider.autoDispose<CreateMeetingNotifier, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(meetingsRepositoryProvider);
    return CreateMeetingNotifier(repository, ref);
  },
);

class CreateMeetingNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetingsRepository _repository;
  final Ref _ref;

  CreateMeetingNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createMeeting({
    required MeetingTopic topic,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repository.createMeeting(
      topic: topic,
      date: date,
      time: time,
    );

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (meeting) {
        state = const AsyncValue.data(null);
        // Refresh the list if we were displaying one
        // ignore: unused_result
        _ref.refresh(meetingsListProvider);
      },
    );
  }
}
