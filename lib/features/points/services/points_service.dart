import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';

/// Ledger entry types for Civic Points.
enum PointLedgerType { funEarn, adSpend }

extension PointLedgerTypeX on PointLedgerType {
  String get value {
    switch (this) {
      case PointLedgerType.funEarn:
        return 'fun_earn';
      case PointLedgerType.adSpend:
        return 'ad_spend';
    }
  }
}

/// Atomic earn / spend for Civic Points stored on `users/{uid}`.
class PointsService {
  PointsService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> get _ledger =>
      _firestore.collection(AppConstants.pointLedgerCollection);

  Stream<int> watchBalance(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      final data = doc.data();
      return (data?['pointsBalance'] as num?)?.toInt() ?? 0;
    });
  }

  Future<int> getBalance(String uid) async {
    final doc = await _userRef(uid).get();
    return (doc.data()?['pointsBalance'] as num?)?.toInt() ?? 0;
  }

  /// Awards [amount] points. Optionally stamps [lastFunPlayDate] (yyyy-MM-dd).
  Future<int> earnPoints({
    required String uid,
    required int amount,
    required PointLedgerType type,
    String? lastFunPlayDate,
    String? note,
  }) async {
    if (amount <= 0) throw Exception('Earn amount must be positive.');
    return _firestore.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final current = (data['pointsBalance'] as num?)?.toInt() ?? 0;
      final next = current + amount;
      final update = <String, dynamic>{
        'pointsBalance': next,
        'pointsUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (lastFunPlayDate != null) {
        update['lastFunPlayDate'] = lastFunPlayDate;
      }
      if (snap.exists) {
        tx.update(ref, update);
      } else {
        tx.set(ref, update, SetOptions(merge: true));
      }
      tx.set(_ledger.doc(), {
        'uid': uid,
        'type': type.value,
        'amount': amount,
        if (note != null) 'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
  }

  /// Deducts [amount] points. Throws if balance is insufficient.
  Future<int> spendPoints({
    required String uid,
    required int amount,
    required PointLedgerType type,
    String? note,
    String? relatedId,
  }) async {
    if (amount <= 0) throw Exception('Spend amount must be positive.');
    return _firestore.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final current = (data['pointsBalance'] as num?)?.toInt() ?? 0;
      if (current < amount) {
        throw Exception(
          'Not enough points. You have $current, need $amount.',
        );
      }
      final next = current - amount;
      tx.set(
        ref,
        {
          'pointsBalance': next,
          'pointsUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(_ledger.doc(), {
        'uid': uid,
        'type': type.value,
        'amount': -amount,
        if (note != null) 'note': note,
        if (relatedId != null) 'relatedId': relatedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
  }

  Future<String?> getLastFunPlayDate(String uid) async {
    final doc = await _userRef(uid).get();
    return doc.data()?['lastFunPlayDate'] as String?;
  }

  /// Points awarded for a weekday check-in. Monday is 5, matching the rewards screen.
  static int pointsForWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 5;
      case DateTime.tuesday:
        return 10;
      case DateTime.wednesday:
        return 5;
      case DateTime.thursday:
        return 10;
      case DateTime.friday:
        return 5;
      case DateTime.saturday:
        return 15;
      default:
        return 10;
    }
  }

  Stream<CivicRewardsState> watchRewards(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return CivicRewardsState(
        balance: (data['pointsBalance'] as num?)?.toInt() ?? 0,
        checkIns: _readCheckIns(data['rewardCheckIns']),
      );
    });
  }

  /// Claims today's check-in once. Stores the date on the user and writes the ledger.
  Future<int> claimCheckIn({
    required String uid,
    required String dateKey,
    required int amount,
  }) async {
    if (amount <= 0) throw Exception('Earn amount must be positive.');
    return _firestore.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final checkIns = _readCheckIns(data['rewardCheckIns']);
      if (checkIns.containsKey(dateKey)) {
        throw Exception('You already checked in today.');
      }
      checkIns[dateKey] = amount;
      final current = (data['pointsBalance'] as num?)?.toInt() ?? 0;
      final next = current + amount;
      final update = <String, dynamic>{
        'pointsBalance': next,
        'pointsUpdatedAt': FieldValue.serverTimestamp(),
        'lastFunPlayDate': dateKey,
        'rewardCheckIns': checkIns,
      };
      if (snap.exists) {
        tx.update(ref, update);
      } else {
        tx.set(ref, update, SetOptions(merge: true));
      }
      tx.set(_ledger.doc(), {
        'uid': uid,
        'type': PointLedgerType.funEarn.value,
        'amount': amount,
        'note': 'Daily check-in',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
  }

  static Map<String, int> _readCheckIns(Object? raw) {
    final map = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) map[key.toString()] = value.toInt();
      });
    }
    return map;
  }

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class CivicRewardsState {
  const CivicRewardsState({required this.balance, required this.checkIns});

  final int balance;
  final Map<String, int> checkIns;
}
