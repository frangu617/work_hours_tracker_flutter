import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;
  final bool isEditMode;
  final VoidCallback onDelete;

  const EntryCard({
    required this.entry,
    required this.isEditMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clock In: ${_formatDateTime(entry.clockIn)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme
                          .textTheme.bodyLarge?.color, // Use theme text color
                    ),
                  ),
                  if (entry.clockOut != null)
                    Text(
                      'Clock Out: ${_formatDateTime(entry.clockOut!)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme
                            .textTheme.bodyLarge?.color, // Use theme text color
                      ),
                    ),
                ],
              ),
            ),
            if (isEditMode)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatDateTime(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('EEEE, h:mm a, MM/dd/yyyy').format(dateTime);
  }
}
