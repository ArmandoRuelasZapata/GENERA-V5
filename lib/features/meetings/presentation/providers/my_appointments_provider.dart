import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/appointment_entity.dart';
import 'meetings_provider.dart';

part 'my_appointments_provider.g.dart';

@riverpod
class MyAppointments extends _$MyAppointments {
  @override
  Future<List<AppointmentEntity>> build() async {
    final repository = ref.watch(meetingsRepositoryProvider);
    final result = await repository.getMeetings();

    return result.fold(
      (error) => throw Exception(error),
      (meetings) {
        final now = DateTime.now();

        final appointments = meetings.map(
          (meeting) {
            final appointmentDate = DateTime(
              meeting.date.year,
              meeting.date.month,
              meeting.date.day,
              meeting.time.hour,
              meeting.time.minute,
            );

            return AppointmentEntity(
              id: meeting.id,
              serviceName: meeting.clientName ?? meeting.topic.label,
              date: appointmentDate,
              price: 0.0,
              status: appointmentDate.isAfter(now) ? 'upcoming' : 'completed',
              notes:
                  'Cita agendada: ${DateFormat('HH:mm').format(appointmentDate)}',
            );
          },
        ).toList();

        appointments.sort((a, b) {
          if (a.status == 'upcoming' && b.status != 'upcoming') return -1;
          if (a.status != 'upcoming' && b.status == 'upcoming') return 1;
          if (a.status == 'upcoming') return a.date.compareTo(b.date);
          return b.date.compareTo(a.date);
        });

        return appointments;
      },
    );
  }
}
