import 'package:flutter/material.dart';

import '../models/meetup_suggestion.dart';

/// Displays safe meetup suggestions for in-person handoffs.
class MeetupSuggestionsWidget extends StatelessWidget {
  const MeetupSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.selectedLabel,
    this.onSelect,
    this.loading = false,
  });

  final List<MeetupSuggestion> suggestions;
  final String? selectedLabel;
  final void Function(MeetupSuggestion suggestion)? onSelect;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.place_outlined, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Safe meetup suggestions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Meet in daylight at a busy public place. Share your chosen spot with the other party.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((suggestion) {
          final selected = selectedLabel != null &&
              selectedLabel!.trim() == suggestion.label.trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onSelect == null ? null : () => onSelect!(suggestion),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.location_on_outlined,
                        size: 20,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestion.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
