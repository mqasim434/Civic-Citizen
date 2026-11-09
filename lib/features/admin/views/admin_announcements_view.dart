import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_announcement.dart';
import '../../../core/services/announcement_service.dart';
import '../../announcements/widgets/announcement_analytics_panel.dart';
import '../../auth/controllers/auth_controller.dart';
import '../ui/admin_ui.dart';

/// Form to publish a new announcement (opened from Broadcast).
class AdminCreateAnnouncementView extends StatefulWidget {
  const AdminCreateAnnouncementView({super.key});

  @override
  State<AdminCreateAnnouncementView> createState() =>
      _AdminCreateAnnouncementViewState();
}

class _AdminCreateAnnouncementViewState
    extends State<AdminCreateAnnouncementView> {
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
      Navigator.of(context).pop();
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

    return AdminPage(
      title: 'Create Announcement',
      leading: const AdminBackButton(),
      body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
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
        AdminButton(
          label: _saving ? 'Publishing…' : 'Publish announcement',
          icon: Icons.send_rounded,
          busy: _saving,
          onPressed: _publish,
        ),
      ],
    ),
    );
  }
}

/// Broadcast list: create button and recent announcements.
class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  static const _previewCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return AdminPage(
      title: 'Announcements',
      leading: const AdminBackButton(),
      body: StreamBuilder<List<AppAnnouncement>>(
        stream: context.read<AnnouncementService>().watchAllForAdmin(),
        builder: (context, snap) {
          final items = snap.data ?? const <AppAnnouncement>[];
          final shown =
              _showAll ? items : items.take(_previewCount).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              AdminButton(
                label: 'Create Announcement',
                icon: Icons.add_circle_rounded,
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute<void>(
                  builder: (_) => const AdminCreateAnnouncementView(),
                )),
              ),
              const SizedBox(height: 22),
              AdminSectionHeader(
                title: 'Recent Announcements',
                actionLabel: items.length > _previewCount
                    ? (_showAll ? 'Show less' : 'View All')
                    : null,
                onAction: () => setState(() => _showAll = !_showAll),
              ),
              const SizedBox(height: 12),
              if (snap.hasError)
                Text('Error: ${snap.error}', style: AdminText.body(p))
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                const AdminEmpty(
                  icon: Icons.campaign_outlined,
                  message: 'No announcements yet',
                )
              else
                for (final a in shown) _AnnouncementTile(announcement: a),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});

  final AppAnnouncement announcement;

  void _showAnalytics(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              announcement.title,
              style: AdminText.title(AdminPalette.of(ctx), size: 18),
            ),
            const SizedBox(height: 12),
            AnnouncementAnalyticsPanel(announcement: announcement),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final service = context.read<AnnouncementService>();
    final a = announcement;

    final Widget leading = a.hasImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              a.imageUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.campaign_rounded, color: p.primary, size: 40),
            ),
          )
        : SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              a.hasPoll ? Icons.poll_rounded : Icons.campaign_rounded,
              color: p.primary,
              size: 40,
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: p.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.title(p, size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  a.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body(p, size: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 14, color: p.muted),
                    const SizedBox(width: 4),
                    Text(
                      a.createdAt == null ? '' : adminDate(a.createdAt!),
                      style: AdminText.body(p, size: 11.5),
                    ),
                    if (a.hasPoll) ...[
                      const SizedBox(width: 8),
                      AdminPill.blue(context, 'Poll'),
                    ],
                    const Spacer(),
                    a.active
                        ? AdminPill.green(context, 'Active')
                        : AdminPill.grey(context, 'Inactive'),
                    const SizedBox(width: 6),
                  ],
                ),
              ],
            ),
          ),
          AdminMoreButton<String>(
            onSelected: (v) {
              if (v == 'analytics') _showAnalytics(context);
              if (v == 'toggle') service.setActive(a.id, active: !a.active);
            },
            itemBuilder: (_) => [
              adminMenuItem(
                'analytics',
                Icons.bar_chart_rounded,
                'View analytics',
              ),
              a.active
                  ? adminMenuItem(
                      'toggle',
                      Icons.visibility_off_outlined,
                      'Deactivate',
                    )
                  : adminMenuItem(
                      'toggle',
                      Icons.visibility_outlined,
                      'Activate',
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
