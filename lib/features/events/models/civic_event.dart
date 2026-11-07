import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  community,
  cleanup,
  workshop,
  fundraiser,
  other,
}

extension EventTypeX on EventType {
  String get value {
    switch (this) {
      case EventType.community:
        return 'community';
      case EventType.cleanup:
        return 'cleanup';
      case EventType.workshop:
        return 'workshop';
      case EventType.fundraiser:
        return 'fundraiser';
      case EventType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case EventType.community:
        return 'Community';
      case EventType.cleanup:
        return 'Cleanup';
      case EventType.workshop:
        return 'Workshop';
      case EventType.fundraiser:
        return 'Fundraiser';
      case EventType.other:
        return 'Other';
    }
  }

  static EventType fromValue(String? v) {
    switch (v) {
      case 'cleanup':
        return EventType.cleanup;
      case 'workshop':
        return EventType.workshop;
      case 'fundraiser':
        return EventType.fundraiser;
      case 'other':
        return EventType.other;
      default:
        return EventType.community;
    }
  }
}

class CivicEvent {
  const CivicEvent({
    required this.id,
    required this.title,
    required this.city,
    required this.location,
    required this.eventType,
    required this.isOpen,
    required this.active,
    required this.requirements,
    required this.details,
    this.eventDate,
    this.documentUrl,
    this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  factory CivicEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CivicEvent(
      id: doc.id,
      title: d['title'] as String? ?? '',
      city: d['city'] as String? ?? '',
      location: d['location'] as String? ?? '',
      eventType: EventTypeX.fromValue(d['eventType'] as String?),
      isOpen: d['isOpen'] as bool? ?? true,
      active: d['active'] as bool? ?? false,
      requirements: d['requirements'] as String? ?? '',
      details: d['details'] as String? ?? '',
      eventDate: (d['eventDate'] as Timestamp?)?.toDate(),
      documentUrl: d['documentUrl'] as String?,
      imageUrl: d['imageUrl'] as String?,
      createdBy: d['createdBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String title;
  final String city;
  final String location;
  final EventType eventType;
  final bool isOpen;
  final bool active;
  final String requirements;
  final String details;
  final DateTime? eventDate;
  final String? documentUrl;
  final String? imageUrl;
  final String? createdBy;
  final DateTime? createdAt;
}
