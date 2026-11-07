import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/civic_event.dart';
import '../services/event_service.dart';

class AdminEventsView extends StatefulWidget {
  const AdminEventsView({super.key});

  @override
  State<AdminEventsView> createState() => _AdminEventsViewState();
}

class _AdminEventsViewState extends State<AdminEventsView> {
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _location = TextEditingController();
  final _requirements = TextEditingController();
  final _details = TextEditingController();
  final _picker = ImagePicker();

  EventType _type = EventType.community;
  DateTime _date = DateTime.now().add(const Duration(days: 3));
  bool _isOpen = true;
  bool _saving = false;
  File? _cover;
  File? _document;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _location.dispose();
    _requirements.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _cover = File(picked.path));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _document = File(path));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _date.hour,
        t?.minute ?? _date.minute,
      );
    });
  }

  Future<void> _publish() async {
    final admin = context.read<AuthController>().user;
    if (admin == null) return;
    setState(() => _saving = true);
    try {
      await context.read<EventService>().createEvent(
            adminUid: admin.uid,
            title: _title.text,
            city: _city.text,
            location: _location.text,
            eventType: _type,
            eventDate: _date,
            requirements: _requirements.text,
            details: _details.text,
            isOpen: _isOpen,
            coverImage: _cover,
            documentFile: _document,
          );
      if (!mounted) return;
      _title.clear();
      _city.clear();
      _location.clear();
      _requirements.clear();
      _details.clear();
      setState(() {
        _cover = null;
        _document = null;
        _isOpen = true;
        _type = EventType.community;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event published')),
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
    final service = context.read<EventService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Publish event', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Event name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          decoration: const InputDecoration(
            labelText: 'Venue / location',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<EventType>(
          value: _type,
          decoration: const InputDecoration(
            labelText: 'Event type',
            border: OutlineInputBorder(),
          ),
          items: EventType.values
              .map(
                (t) => DropdownMenuItem(value: t, child: Text(t.label)),
              )
              .toList(),
          onChanged: (v) => setState(() => _type = v ?? EventType.community),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date & time'),
          subtitle: Text(_date.toLocal().toString().split('.').first),
          trailing: const Icon(Icons.calendar_month_rounded),
          onTap: _pickDate,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Event is open'),
          value: _isOpen,
          onChanged: (v) => setState(() => _isOpen = v),
        ),
        TextField(
          controller: _requirements,
          decoration: const InputDecoration(
            labelText: 'Requirements',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _details,
          decoration: const InputDecoration(
            labelText: 'Details',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_cover == null ? 'Cover image' : 'Change cover'),
            ),
            TextButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_document == null ? 'Document' : 'Change doc'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _publish,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publish event'),
        ),
        const SizedBox(height: 28),
        Text('All events', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<CivicEvent>>(
          stream: service.watchAllEventsForAdmin(),
          builder: (context, snap) {
            final events = snap.data ?? [];
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No events yet'),
              );
            }
            return Column(
              children: events
                  .map(
                    (e) => Card(
                      child: ListTile(
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.city} · ${e.eventType.label} · '
                          '${e.isOpen ? 'Open' : 'Closed'} · '
                          '${e.active ? 'Visible' : 'Hidden'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'toggle_open') {
                              await service.setOpen(e.id, !e.isOpen);
                            } else if (v == 'toggle_active') {
                              await service.setActive(e.id, !e.active);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle_open',
                              child: Text(
                                e.isOpen ? 'Mark closed' : 'Mark open',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_active',
                              child: Text(
                                e.active ? 'Hide from users' : 'Show to users',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
