import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/meeting_request.dart';
import '../../domain/repositories/meetings_repository.dart';

class MockMeetingsRepository implements MeetingsRepository {
  // Static/Singleton-like list to persist data in memory during session
  static final List<MeetingRequest> _meetings = [];

  @override
  Future<Either<String, List<MeetingRequest>>> getMeetings() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Sort by date descending
    _meetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(_meetings);
  }

  @override
  Future<Either<String, MeetingRequest>> createMeeting({
    required MeetingTopic topic,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    await Future.delayed(
        const Duration(milliseconds: 1500)); // Simulate net delay

    final newMeeting = MeetingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: topic,
      date: date,
      time: time,
      status: MeetingStatus.pending,
      createdAt: DateTime.now(),
    );

    _meetings.add(newMeeting);
    return Right(newMeeting);
  }
}
