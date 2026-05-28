import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';
import '../../domain/entities/meeting_request.dart';
import '../providers/meetings_provider.dart';

class MeetingListScreen extends ConsumerWidget {
  const MeetingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reuniones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: meetingsAsync.when(
        data: (meetings) {
          if (meetings.isEmpty) {
            return const AppEmptyWidget(
              message: 'No tienes reuniones programadas aún.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: meetings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _MeetingCard(meeting: meeting, isDark: isDark);
            },
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, stack) => AppErrorWidget(
          message: 'Error al cargar reuniones: $err',
          onRetry: () => ref.refresh(meetingsListProvider),
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingRequest meeting;
  final bool isDark;

  const _MeetingCard({
    required this.meeting,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE d, MMMM', 'es');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: meeting.topic.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: meeting.topic.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  meeting.topic.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: meeting.topic.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusBadge(status: meeting.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                dateFormatter.format(meeting.date),
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                meeting.time.format(context),
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MeetingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
