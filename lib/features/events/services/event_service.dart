import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/imagekit_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/imagekit_service.dart';
import '../models/civic_event.dart';

class EventService {
  EventService({ImageKitService? imageKit})
      : _firestore = FirebaseFirestore.instance,
        _imageKit = imageKit ?? ImageKitService(ImageKitConfig.instance);

  final FirebaseFirestore _firestore;
  final ImageKitService _imageKit;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(AppConstants.eventsCollection);

  Stream<List<CivicEvent>> watchActiveEvents() {
    return _events
        .where('active', isEqualTo: true)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CivicEvent.fromFirestore).toList());
  }

  Stream<List<CivicEvent>> watchAllEventsForAdmin() {
    return _events
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snap) => snap.docs.map(CivicEvent.fromFirestore).toList());
  }

  Future<CivicEvent?> getEvent(String id) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    return CivicEvent.fromFirestore(doc);
  }

  Future<String> createEvent({
    required String adminUid,
    required String title,
    required String city,
    required String location,
    required EventType eventType,
    required DateTime eventDate,
    required String requirements,
    required String details,
    required bool isOpen,
    File? coverImage,
    File? documentFile,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) throw Exception('Enter an event title.');

    final doc = _events.doc();
    String? imageUrl;
    String? documentUrl;

    if (coverImage != null) {
      imageUrl = await _imageKit.upload(
        file: coverImage,
        folder: '${AppConstants.eventDocsPath}/${doc.id}/cover',
      );
    }
    if (documentFile != null) {
      documentUrl = await _imageKit.upload(
        file: documentFile,
        folder: '${AppConstants.eventDocsPath}/${doc.id}/docs',
        fileName: documentFile.uri.pathSegments.last,
      );
    }

    await doc.set({
      'title': trimmedTitle,
      'city': city.trim(),
      'location': location.trim(),
      'eventType': eventType.value,
      'eventDate': Timestamp.fromDate(eventDate),
      'isOpen': isOpen,
      'active': true,
      'requirements': requirements.trim(),
      'details': details.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (documentUrl != null) 'documentUrl': documentUrl,
      'createdBy': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection(AppConstants.eventAlertsCollection).add({
      'eventId': doc.id,
      'title': trimmedTitle,
      'city': city.trim(),
      'authorId': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> setOpen(String eventId, bool isOpen) async {
    await _events.doc(eventId).update({
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String eventId, bool active) async {
    await _events.doc(eventId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
