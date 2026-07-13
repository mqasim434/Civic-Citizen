import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_announcement.dart';
import '../../../core/services/announcement_service.dart';
import '../../announcements/widgets/announcement_analytics_panel.dart';
import '../../auth/controllers/auth_controller.dart';

class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _pollQuestionController = TextEditingController();
  final _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _saving = false;
  bool _includePoll = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _pollQuestionController.dispose();
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= 5) return;
    setState(() => _pollOptionControllers.add(TextEditingController()));
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) return;
    _pollOptionControllers.removeAt(index).dispose();
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedImage = File(picked.path));
  }

  void _clearImage() => setState(() => _selectedImage = null);

  Future<void> _publish() async {
    final admin = context.read<AuthController>().user;
    if (admin == null) return;

    setState(() => _saving = true);
    try {
      await context.read<AnnouncementService>().create(
            adminUid: admin.uid,
            title: _titleController.text,
            body: _bodyController.text,
            imageFile: _selectedImage,
            pollQuestion: _includePoll ? _pollQuestionController.text : null,
            pollOptionTexts: _includePoll
                ? _pollOptionControllers.map((c) => c.text).toList()
                : null,
          );
      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      _pollQuestionController.clear();
      for (final c in _pollOptionControllers) {
        c.clear();
      }
      setState(() {
        _selectedImage = null;
        _includePoll = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<AnnouncementService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Broadcast to all users',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Active announcements appear as a popup when users open the app. '
          'Add an optional image or interactive poll.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include poll'),
          subtitle: const Text('Users can vote once; results appear below.'),
          value: _includePoll,
          onChanged: _saving ? null : (v) => setState(() => _includePoll = v),
        ),
        if (_includePoll) ...[
          TextField(
            controller: _pollQuestionController,
            decoration: const InputDecoration(
              labelText: 'Poll question',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          ...List.generate(_pollOptionControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollOptionControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Option ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      onPressed: _saving ? null : () => _removePollOption(i),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                ],
              ),
            );
          }),
          if (_pollOptionControllers.length < 5)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _saving ? null : _addPollOption,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add option'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Optional image',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _saving ? null : _clearImage,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Remove image'),
            ),
          ),
        ] else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ],
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _publish,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_saving ? 'Publishing…' : 'Publish announcement'),
        ),
        const SizedBox(height: 32),
        Text(
          'Recent announcements',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AppAnnouncement>>(
          stream: service.watchAllForAdmin(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Error: ${snap.error}');
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Text(
                'No announcements yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            return Column(
              children:
                  items.map((a) => _AnnouncementTile(announcement: a)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AnnouncementTile extends StatefulWidget {
  const _AnnouncementTile({required this.announcement});

  final AppAnnouncement announcement;

  @override
  State<_AnnouncementTile> createState() => _AnnouncementTileState();
}

class _AnnouncementTileState extends State<_AnnouncementTile> {
  bool _showAnalytics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<AnnouncementService>();
    final announcement = widget.announcement;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (announcement.hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                announcement.imageUrl!,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ListTile(
            title: Text(announcement.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  announcement.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      announcement.active ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: announcement.active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (announcement.hasPoll)
                      Text(
                        'Poll',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            trailing: announcement.active
                ? TextButton(
                    onPressed: () => service.setActive(
                      announcement.id,
                      active: false,
                    ),
                    child: const Text('Deactivate'),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _showAnalytics = !_showAnalytics),
                  icon: Icon(
                    _showAnalytics
                        ? Icons.expand_less_rounded
                        : Icons.bar_chart_rounded,
                  ),
                  label: Text(
                    _showAnalytics ? 'Hide analytics' : 'View analytics',
                  ),
                ),
                if (_showAnalytics) ...[
                  const SizedBox(height: 12),
                  AnnouncementAnalyticsPanel(announcement: announcement),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
