import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../admin/ui/admin_ui.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/civic_event.dart';
import '../services/event_service.dart';

/// Form to publish a new event (opened from the Events page).
class AdminCreateEventView extends StatefulWidget {
  const AdminCreateEventView({super.key});

  @override
  State<AdminCreateEventView> createState() => _AdminCreateEventViewState();
}

class _AdminCreateEventViewState extends State<AdminCreateEventView> {
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
    return AdminPage(
      title: 'Create Event',
      leading: const AdminBackButton(),
      body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
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
        AdminButton(
          label: 'Publish event',
          icon: Icons.send_rounded,
          busy: _saving,
          onPressed: _publish,
        ),
      ],
    ),
    );
  }
}

enum _EventFilter { all, upcoming, ongoing, past }

enum _EventPhase { upcoming, ongoing, past }

/// Upcoming until it starts, ongoing for the first 24 hours, then past.
_EventPhase _phaseOf(CivicEvent e) {
  final date = e.eventDate;
  if (date == null) return e.isOpen ? _EventPhase.upcoming : _EventPhase.past;
  final now = DateTime.now();
  if (date.isAfter(now)) return _EventPhase.upcoming;
  if (now.isBefore(date.add(const Duration(hours: 24)))) {
    return _EventPhase.ongoing;
  }
  return _EventPhase.past;
}

/// Admin events list with status chips and a type filter.
class AdminEventsView extends StatefulWidget {
  const AdminEventsView({super.key});

  @override
  State<AdminEventsView> createState() => _AdminEventsViewState();
}

class _AdminEventsViewState extends State<AdminEventsView> {
  _EventFilter _filter = _EventFilter.all;
  EventType? _type;

  Future<void> _pickType() async {
    // -1 stands for "All types" so it differs from a dismissed sheet (null).
    final picked = await adminPickOption<int>(
      context,
      title: 'Event type',
      options: [-1, for (final t in EventType.values) t.index],
      selected: _type?.index ?? -1,
      labelOf: (i) => i < 0 ? 'All types' : EventType.values[i].label,
    );
    if (picked == null || !mounted) return;
    setState(() => _type = picked < 0 ? null : EventType.values[picked]);
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final service = context.read<EventService>();
    return AdminPage(
      title: 'Events',
      leading: const AdminBackButton(),
      actions: [
        Badge(
          isLabelVisible: _type != null,
          smallSize: 8,
          backgroundColor: p.amber,
          offset: const Offset(-8, 8),
          child: AdminHeaderIcon(
            tooltip: 'Event type',
            icon: Icons.filter_list_rounded,
            onPressed: _pickType,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: AdminButton(
                label: 'Create Event',
                icon: Icons.add_circle_rounded,
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute<void>(
                  builder: (_) => const AdminCreateEventView(),
                )),
              ),
            ),
          ),
          AdminChipBar<_EventFilter>(
            options: _EventFilter.values,
            selected: _filter,
            expand: true,
            onSelected: (f) => setState(() => _filter = f),
            labelOf: (f) {
              switch (f) {
                case _EventFilter.all:
                  return 'All';
                case _EventFilter.upcoming:
                  return 'Upcoming';
                case _EventFilter.ongoing:
                  return 'Ongoing';
                case _EventFilter.past:
                  return 'Past';
              }
            },
          ),
          Expanded(
            child: StreamBuilder<List<CivicEvent>>(
              stream: service.watchAllEventsForAdmin(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return AdminEmpty(
                    icon: Icons.error_outline_rounded,
                    message: 'Could not load events.\n${snap.error}',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snap.data!.where((e) {
                  if (_type != null && e.eventType != _type) return false;
                  final phase = _phaseOf(e);
                  switch (_filter) {
                    case _EventFilter.all:
                      return true;
                    case _EventFilter.upcoming:
                      return phase == _EventPhase.upcoming;
                    case _EventFilter.ongoing:
                      return phase == _EventPhase.ongoing;
                    case _EventFilter.past:
                      return phase == _EventPhase.past;
                  }
                }).toList();
                if (events.isEmpty) {
                  return const AdminEmpty(
                    icon: Icons.event_busy_rounded,
                    message: 'No events here',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _EventCard(event: events[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CivicEvent event;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final service = context.read<EventService>();
    final e = event;
    final date = e.eventDate;
    final phase = _phaseOf(e);
    final location = [e.location, e.city]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    final statusPill = switch (phase) {
      _EventPhase.upcoming => AdminPill.green(context, 'Upcoming'),
      _EventPhase.ongoing => AdminPill.blue(context, 'Ongoing'),
      _EventPhase.past => AdminPill.grey(context, 'Past'),
    };

    final image = e.imageUrl;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: p.cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routeEventDetail,
            arguments: e,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: image != null && image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _EventPlaceholder(p: p),
                          )
                        : _EventPlaceholder(p: p),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AdminText.title(p, size: 15),
                      ),
                      const SizedBox(height: 6),
                      if (date != null)
                        _InfoLine(
                          icon: Icons.calendar_month_outlined,
                          text: '${adminDate(date)} • ${adminTime(date)}',
                        ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _InfoLine(icon: Icons.location_on_outlined, text: location),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (!e.active) ...[
                            AdminPill.grey(context, 'Hidden'),
                            const SizedBox(width: 6),
                          ],
                          if (!e.isOpen) ...[
                            AdminPill.red(context, 'Closed'),
                            const SizedBox(width: 6),
                          ],
                          const Spacer(),
                          statusPill,
                          const SizedBox(width: 6),
                        ],
                      ),
                    ],
                  ),
                ),
                AdminMoreButton<String>(
                  onSelected: (v) async {
                    if (v == 'open') await service.setOpen(e.id, !e.isOpen);
                    if (v == 'active') await service.setActive(e.id, !e.active);
                  },
                  itemBuilder: (_) => [
                    adminMenuItem(
                      'open',
                      e.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      e.isOpen ? 'Mark closed' : 'Mark open',
                    ),
                    adminMenuItem(
                      'active',
                      e.active
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      e.active ? 'Hide from users' : 'Show to users',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPlaceholder extends StatelessWidget {
  const _EventPlaceholder({required this.p});

  final AdminPalette p;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: p.softGreen,
        child: Icon(Icons.event_rounded, color: p.softGreenText, size: 32),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: p.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AdminText.body(p, size: 12),
          ),
        ),
      ],
    );
  }
}
