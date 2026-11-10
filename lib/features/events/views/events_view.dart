import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../models/civic_event.dart';
import '../services/event_service.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class EventsView extends StatelessWidget {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), bottom: const WaveHeaderSpacer(), title: const Text('Community events')),
      body: StreamBuilder<List<CivicEvent>>(
        stream: context.read<EventService>().watchActiveEvents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No events right now. Admins will publish community events here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                child: InkWell(
                  onTap: () => navigatorKey.currentState?.pushNamed(
                    AppConstants.routeEventDetail,
                    arguments: e,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_city_rounded,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(e.city.isEmpty ? 'City TBA' : e.city),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.event_rounded,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              e.eventDate == null
                                  ? 'Date TBA'
                                  : e.eventDate!
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(e.eventType.label),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(e.isOpen ? 'Open' : 'Closed'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: e.isOpen
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.errorContainer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EventDetailView extends StatelessWidget {
  const EventDetailView({
    super.key,
    this.event,
    this.eventId,
  }) : assert(event != null || eventId != null);

  final CivicEvent? event;
  final String? eventId;

  Future<void> _openDoc(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (event != null) return _body(context, event!);
    return FutureBuilder<CivicEvent?>(
      future: context.read<EventService>().getEvent(eventId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final e = snap.data;
        if (e == null) {
          return Scaffold(
            appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), bottom: const WaveHeaderSpacer(), title: const Text('Event')),
            body: const Center(child: Text('Event not found')),
          );
        }
        return _body(context, e);
      },
    );
  }

  Widget _body(BuildContext context, CivicEvent event) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), bottom: const WaveHeaderSpacer(), title: const Text('Event')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                event.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (event.imageUrl != null) const SizedBox(height: 16),
          Text(event.title, style: theme.textTheme.displaySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.location_city_rounded,
                  label: event.city.isEmpty ? 'City TBA' : event.city,
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.place_outlined,
                  label: event.location.isEmpty ? 'Venue TBA' : event.location,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.event_rounded,
                  label: event.eventDate == null
                      ? 'Date TBA'
                      : event.eventDate!.toLocal().toString().split('.').first,
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.category_outlined,
                  label: event.eventType.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                event.isOpen ? 'Event is open' : 'Event is closed',
              ),
              backgroundColor: event.isOpen
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.errorContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text('Requirements', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            event.requirements.isEmpty ? 'None listed' : event.requirements,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            event.details.isEmpty ? 'No extra details.' : event.details,
            style: theme.textTheme.bodyLarge,
          ),
          if (event.documentUrl != null &&
              event.documentUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _openDoc(event.documentUrl!),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open document'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
