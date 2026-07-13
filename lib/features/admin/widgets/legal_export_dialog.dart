import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/legal_export_service.dart';

Future<void> showLegalExportDialog(
  BuildContext context, {
  required String userId,
  required String userLabel,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _LegalExportDialog(
      userId: userId,
      userLabel: userLabel,
    ),
  );
}

class _LegalExportDialog extends StatefulWidget {
  const _LegalExportDialog({
    required this.userId,
    required this.userLabel,
  });

  final String userId;
  final String userLabel;

  @override
  State<_LegalExportDialog> createState() => _LegalExportDialogState();
}

class _LegalExportDialogState extends State<_LegalExportDialog> {
  late Future<String> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = context.read<LegalExportService>().buildEvidencePackage(
          widget.userId,
        );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evidence report copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Legal evidence export'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<String>(
          future: _reportFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Text(
                'Could not build export:\n${snap.error}',
                style: TextStyle(color: theme.colorScheme.error),
              );
            }

            final report = snap.data ?? '';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Package for ${widget.userLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 360),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FutureBuilder<String>(
          future: _reportFuture,
          builder: (context, snap) {
            return FilledButton.icon(
              onPressed: snap.hasData ? () => _copy(snap.data!) : null,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy report'),
            );
          },
        ),
      ],
    );
  }
}
