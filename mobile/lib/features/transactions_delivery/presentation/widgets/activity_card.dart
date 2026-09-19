import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'status_badge.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final double total;
  final VoidCallback onTap;

  const ActivityCard({super.key, required this.title, required this.subtitle, required this.status, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen)),
              ],
            ),
          ),
        ),
      );
}
