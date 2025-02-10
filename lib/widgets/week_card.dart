import 'package:flutter/material.dart';
import '../models/entry.dart';
import 'entry_card.dart';

class WeekCard extends StatelessWidget {
  final String weekStartDate;
  final Map<String, List<Entry>> dailyEntries;
  final bool isEditMode;
  final Function(int) onDeleteEntry;

  const WeekCard({
    required this.weekStartDate,
    required this.dailyEntries,
    required this.isEditMode,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Week Starting: $weekStartDate',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color, // Use theme text color
            ),
          ),
        ),
        ...dailyEntries.entries.map((dayEntry) {
          final String dayKey = dayEntry.key;
          final List<Entry> entries = dayEntry.value;

          double totalHours = 0;
          for (var entry in entries) {
            if (entry.clockOut != null) {
              final DateTime clockIn = DateTime.parse(entry.clockIn);
              final DateTime clockOut = DateTime.parse(entry.clockOut!);
              totalHours += clockOut.difference(clockIn).inMinutes / 60.0;
            }
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: theme.cardTheme.color, // Use theme card background color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayKey,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme
                          .textTheme.bodyLarge?.color, // Use theme text color
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entries.map((entry) {
                    return EntryCard(
                      entry: entry,
                      isEditMode: isEditMode,
                      onDelete: () => onDeleteEntry(entry.id!),
                    );
                  }).toList(),
                  Text(
                    'Total Hours: ${totalHours.toStringAsFixed(2)} hours',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme
                          .textTheme.bodyLarge?.color, // Use theme text color
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
