import 'package:cloud_firestore/cloud_firestore.dart';

/// Retries transient Firestore failures (unavailable / deadline exceeded).
Future<T> firestoreWithRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 400),
}) async {
  var delay = initialDelay;
  Object? lastError;
  StackTrace? lastStack;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } on FirebaseException catch (e, st) {
      lastError = e;
      lastStack = st;
      if (!_isTransient(e) || attempt == maxAttempts) rethrow;
      await Future<void>.delayed(delay);
      delay *= 2;
    } catch (e, st) {
      lastError = e;
      lastStack = st;
      rethrow;
    }
  }

  Error.throwWithStackTrace(
    lastError ?? StateError('Firestore retry failed'),
    lastStack ?? StackTrace.current,
  );
}

bool _isTransient(FirebaseException e) {
  switch (e.code) {
    case 'unavailable':
    case 'deadline-exceeded':
    case 'resource-exhausted':
    case 'aborted':
      return true;
    default:
      return false;
  }
}

bool isFirestoreUnavailable(Object error) {
  return error is FirebaseException && _isTransient(error);
}
