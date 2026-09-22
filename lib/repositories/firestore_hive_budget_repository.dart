import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/month.dart';
import 'budget_repository.dart';

/// Firestore is the remote source of truth; Hive caches for offline / fast start.
class FirestoreHiveBudgetRepository implements BudgetRepository {
  FirestoreHiveBudgetRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _boxName = 'budget_cache';
  static const _monthsKey = 'months';
  static const _userKey = 'user_id';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Box<String>? _box;
  String? _userId;
  final _controller = StreamController<List<Month>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  @override
  String? get userId => _userId;

  CollectionReference<Map<String, dynamic>> get _monthsRef {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Repository not initialized — no user id');
    }
    return _firestore.collection('users').doc(uid).collection('months');
  }

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);

    final credential = await _auth.signInAnonymously();
    _userId = credential.user?.uid;
    if (_userId == null) {
      throw StateError('Anonymous sign-in failed');
    }
    await _box!.put(_userKey, _userId!);

    // Enable offline persistence (default on mobile; explicit for clarity).
    _firestore.settings = const Settings(persistenceEnabled: true);

    _remoteSub = _monthsRef.snapshots().listen((snapshot) async {
      final months = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Month.fromMap(data);
      }).toList()
        ..sort((a, b) {
          final byYear = b.year.compareTo(a.year);
          if (byYear != 0) return byYear;
          return b.monthNumber.compareTo(a.monthNumber);
        });
      await _cacheMonths(months);
      if (!_controller.isClosed) {
        _controller.add(months);
      }
    });
  }

  @override
  Future<List<Month>> loadMonths() async {
    final cached = _readCache();
    if (cached.isNotEmpty) return cached;

    final snapshot = await _monthsRef.get();
    final months = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Month.fromMap(data);
    }).toList()
      ..sort((a, b) {
        final byYear = b.year.compareTo(a.year);
        if (byYear != 0) return byYear;
        return b.monthNumber.compareTo(a.monthNumber);
      });
    await _cacheMonths(months);
    return months;
  }

  @override
  Future<void> saveMonths(List<Month> months) async {
    await _cacheMonths(months);
    final batch = _firestore.batch();
    for (final month in months) {
      batch.set(_monthsRef.doc(month.id), month.toMap());
    }
    await batch.commit();
    _controller.add(months);
  }

  @override
  Future<void> upsertMonth(Month month) async {
    final months = await loadMonths();
    final index = months.indexWhere((m) => m.id == month.id);
    if (index >= 0) {
      months[index] = month;
    } else {
      months.add(month);
    }
    months.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      if (byYear != 0) return byYear;
      return b.monthNumber.compareTo(a.monthNumber);
    });
    await _cacheMonths(months);
    await _monthsRef.doc(month.id).set(month.toMap());
    _controller.add(months);
  }

  @override
  Future<void> deleteMonth(String monthId) async {
    final months = await loadMonths()
      ..removeWhere((m) => m.id == monthId);
    await _cacheMonths(months);
    await _monthsRef.doc(monthId).delete();
    _controller.add(months);
  }

  @override
  Stream<List<Month>> watchMonths() async* {
    final cached = _readCache();
    if (cached.isNotEmpty) yield cached;
    yield* _controller.stream;
  }

  List<Month> _readCache() {
    final raw = _box?.get(_monthsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Month.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) {
        final byYear = b.year.compareTo(a.year);
        if (byYear != 0) return byYear;
        return b.monthNumber.compareTo(a.monthNumber);
      });
  }

  Future<void> _cacheMonths(List<Month> months) async {
    final encoded = jsonEncode(months.map((m) => m.toMap()).toList());
    await _box?.put(_monthsKey, encoded);
  }

  Future<void> dispose() async {
    await _remoteSub?.cancel();
    await _controller.close();
  }
}
