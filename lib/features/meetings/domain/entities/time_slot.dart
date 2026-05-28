class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimeSlot &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode =>
      startTime.hashCode ^ endTime.hashCode ^ isAvailable.hashCode;
}
