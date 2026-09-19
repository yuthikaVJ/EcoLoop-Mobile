import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final terminalError = status == 'Cancelled' || status == 'Rejected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: terminalError ? AppColors.errorRed.withOpacity(0.12) : AppColors.mintGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: terminalError ? AppColors.errorRed : AppColors.forestGreen,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
