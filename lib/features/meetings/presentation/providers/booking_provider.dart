import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/time_slot.dart';
import 'meetings_provider.dart';

part 'booking_provider.freezed.dart';
part 'booking_provider.g.dart';

@freezed
class BookingState with _$BookingState {
  const factory BookingState({
    ServiceEntity? selectedService,
    DateTime? selectedDate,
    TimeSlot? selectedTimeSlot,
    @Default(false) bool isLoading,
    String? error,
    String? successMessage,

    /// For "Personalizado" service — the user types their own interest
    String? customInterest,
  }) = _BookingState;
}

@Riverpod(keepAlive: true)
class BookingNotifier extends _$BookingNotifier {
  @override
  BookingState build() {
    return const BookingState();
  }

  void selectService(ServiceEntity service) {
    state = state.copyWith(
        selectedService: service, error: null, customInterest: null);
  }

  void setCustomInterest(String interest) {
    state = state.copyWith(customInterest: interest);
  }

  void selectDate(DateTime date) {
    state =
        state.copyWith(selectedDate: date, selectedTimeSlot: null, error: null);
  }

  void selectTimeSlot(TimeSlot timeSlot) {
    state = state.copyWith(selectedTimeSlot: timeSlot, error: null);
  }

  void reset() {
    state = const BookingState();
  }

  /// Confirms booking via the Make.com webhook.
  /// Uses the provided contact details, or falls back to auth state.
  Future<bool> confirmBooking({
    required String name,
    required String email,
    String? phone,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = state.selectedService;
      final slot = state.selectedTimeSlot;

      if (service == null || slot == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Faltan datos para agendar la cita.',
        );
        return false;
      }

      if (name.isEmpty) {
        state =
            state.copyWith(isLoading: false, error: 'El nombre es requerido.');
        return false;
      }
      if (email.isEmpty) {
        state =
            state.copyWith(isLoading: false, error: 'El correo es requerido.');
        return false;
      }

      // Build interest string
      String interest;
      if (service.id == 'custom') {
        interest = state.customInterest ?? 'Consulta personalizada';
      } else {
        interest = service.name;
      }
      if (notes != null && notes.isNotEmpty) {
        interest = '$interest - $notes';
      }

      final webhookService = ref.read(bookingWebhookServiceProvider);
      await webhookService.scheduleAppointment(
        name: name,
        email: email,
        startTime: slot.startTime,
        interest: interest,
        phone: phone ?? '',
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Cita agendada exitosamente!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

// Services list — these are the real services offered by The Original Lab
// No prices — all consultations are free
@riverpod
Future<List<ServiceEntity>> services(Ref ref) async {
  return const [
    ServiceEntity(
        id: '1',
        name: 'Incubación de Proyectos',
        description:
            'Apoyo para convertir tus sueños en realidad a través de un proceso dinámico.',
        durationMinutes: 60),
    ServiceEntity(
        id: '2',
        name: 'Consultoría TI',
        description:
            'Transformación de organizaciones con soluciones tecnológicas avanzadas.',
        durationMinutes: 60),
    ServiceEntity(
        id: '3',
        name: 'Desarrollo de plataformas',
        description:
            'Implementación de IA, BI y soluciones Cloud para tu empresa.',
        durationMinutes: 60),
    ServiceEntity(
        id: '4',
        name: 'Capacitación',
        description:
            'Cursos y talleres especializados en tecnología para profesionales.',
        durationMinutes: 60),
    ServiceEntity(
        id: '5',
        name: 'Outsourcing',
        description:
            'Soluciones integrales para optimizar recursos y reducir costos.',
        durationMinutes: 60),
    ServiceEntity(
        id: '6',
        name: 'Alianzas Estratégicas',
        description:
            'Colaboración con empresas, universidades y centros de investigación.',
        durationMinutes: 60),
    ServiceEntity(
        id: 'custom',
        name: 'Otro / Personalizado',
        description:
            'Cuéntanos qué necesitas y agendaremos una cita para atenderte.',
        durationMinutes: 60),
  ];
}
