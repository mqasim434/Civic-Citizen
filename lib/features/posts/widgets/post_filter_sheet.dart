import 'package:flutter/material.dart';

import '../utils/post_search_filter.dart';

/// Bottom sheet for category + radius filters on the home feed.
class PostFilterSheet extends StatefulWidget {
  const PostFilterSheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedRadiusKm,
  });

  final List<String> categories;
  final String? selectedCategory;
  final double? selectedRadiusKm;

  static Future<({String? category, double? radiusKm})?> show(
    BuildContext context, {
    required List<String> categories,
    String? selectedCategory,
    double? selectedRadiusKm,
  }) {
    return showModalBottomSheet<({String? category, double? radiusKm})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PostFilterSheet(
        categories: categories,
        selectedCategory: selectedCategory,
        selectedRadiusKm: selectedRadiusKm,
      ),
    );
  }

  @override
  State<PostFilterSheet> createState() => _PostFilterSheetState();
}

class _PostFilterSheetState extends State<PostFilterSheet> {
  late String? _category;
  late double? _radiusKm;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _radiusKm = widget.selectedRadiusKm;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter posts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Text('Nearby radius', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Any distance'),
                selected: _radiusKm == null,
                onSelected: (_) => setState(() => _radiusKm = null),
              ),
              ...PostSearchFilter.radiusOptionsKm.map(
                (km) => ChoiceChip(
                  label: Text('Within ${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km'),
                  selected: _radiusKm == km,
                  onSelected: (_) => setState(() => _radiusKm = km),
                ),
              ),
            ],
          ),
          if (_radiusKm != null) ...[
            const SizedBox(height: 8),
            Text(
              'Uses your current location. Posts without map coordinates are hidden.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Category', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All categories'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              ...widget.categories.map(
                (c) => FilterChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, (category: null, radiusKm: null)),
                child: const Text('Clear all'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  (category: _category, radiusKm: _radiusKm),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
