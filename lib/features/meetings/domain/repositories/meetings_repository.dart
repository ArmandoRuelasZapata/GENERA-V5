import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../entities/meeting_request.dart';

abstract class MeetingsRepository {
  Future<Either<String, List<MeetingRequest>>> getMeetings();
  Future<Either<String, MeetingRequest>> createMeeting({
    required MeetingTopic topic,
    required DateTime date,
    required TimeOfDay time,
  });
}
