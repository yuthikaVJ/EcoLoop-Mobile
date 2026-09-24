import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/transaction_models.dart';

class StatusTimeline extends StatelessWidget {
  final List<StatusHistoryEntry> entries;
  const StatusTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) => Column(
    children: entries.asMap().entries.map((entry) {
      final item = entry.value;
      final last = entry.key == entries.length - 1;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.ecoGreen,
                  size: 20,
                ),
                if (!last)
                  Container(width: 2, height: 52, color: AppColors.mintGreen),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.statusName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.note?.isNotEmpty == true)
                    Text(
                      item.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList(),
  );

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
