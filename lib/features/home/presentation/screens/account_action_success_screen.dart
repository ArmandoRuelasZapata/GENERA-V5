import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

class AccountActionSuccessScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  const AccountActionSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  ConsumerState<AccountActionSuccessScreen> createState() =>
      _AccountActionSuccessScreenState();
}

class _AccountActionSuccessScreenState
    extends ConsumerState<AccountActionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(authProvider.notifier).logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 80,
                color: widget.iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                widget.title,
                style: AppTypography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.subtitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
