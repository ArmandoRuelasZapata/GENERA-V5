import 'package:flutter/material.dart';

enum MeetingTopic {
  projectReview,
  consulting,
  support,
  other;

  String get label {
    switch (this) {
      case MeetingTopic.projectReview:
        return 'Revisión de Proyecto';
      case MeetingTopic.consulting:
        return 'Consultoría General';
      case MeetingTopic.support:
        return 'Soporte Técnico';
      case MeetingTopic.other:
        return 'Otro';
    }
  }

  Color get color {
    switch (this) {
      case MeetingTopic.projectReview:
        return Colors.blue;
      case MeetingTopic.consulting:
        return Colors.purple;
      case MeetingTopic.support:
        return Colors.orange;
      case MeetingTopic.other:
        return Colors.grey;
    }
  }
}

enum MeetingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MeetingStatus.pending:
        return 'Pendiente';
      case MeetingStatus.confirmed:
        return 'Confirmada';
      case MeetingStatus.completed:
        return 'Realizada';
      case MeetingStatus.cancelled:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case MeetingStatus.pending:
        return Colors.orange;
      case MeetingStatus.confirmed:
        return Colors.green;
      case MeetingStatus.completed:
        return Colors.blue;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }
}

class MeetingRequest {
  final String id;
  final MeetingTopic topic;
  final DateTime date;
  final TimeOfDay time;
  final MeetingStatus status;
  final DateTime createdAt;
  final String? clientName;

  const MeetingRequest({
    required this.id,
    required this.topic,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
    this.clientName,
  });
}
