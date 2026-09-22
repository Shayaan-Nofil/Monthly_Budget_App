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

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Box<String>? _box;
  String? _userId;
  bool _hiveReady = false;
  final _controller = StreamController<List<Month>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  @override
  String? get userId => _userId;

  String get _monthsKey => 'months_${_userId ?? 'none'}';

  CollectionReference<Map<String, dynamic>> get _monthsRef {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Repository not bound to a signed-in user');
    }
    return _firestore.collection('users').doc(uid).collection('months');
  }

  @override
  Future<void> init() async {
    if (!_hiveReady) {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _hiveReady = true;
      _firestore.settings = const Settings(persistenceEnabled: true);
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required before loading budget data');
    }
    await bindToUser(user.uid);
  }

  /// Switch Firestore listener + Hive cache to the signed-in uid.
  Future<void> bindToUser(String uid) async {
    if (_userId == uid && _remoteSub != null) return;

    await _remoteSub?.cancel();
    _remoteSub = null;
    _userId = uid;
    await _box?.put('user_id', uid);

    _remoteSub = _monthsRef.snapshots().listen((snapshot) async {
      final months = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Month.fromMap(data);
      }).toList()
        ..sort(_compareMonths);
      await _cacheMonths(months);
      if (!_controller.isClosed) {
        _controller.add(months);
      }
    });
  }

  @override
  Future<void> clearSession() async {
    await _remoteSub?.cancel();
    _remoteSub = null;
    _userId = null;
    if (!_controller.isClosed) {
      _controller.add(const []);
    }
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
      ..sort(_compareMonths);
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
    months.sort(_compareMonths);
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

  int _compareMonths(Month a, Month b) {
    final byYear = b.year.compareTo(a.year);
    if (byYear != 0) return byYear;
    return b.monthNumber.compareTo(a.monthNumber);
  }

  List<Month> _readCache() {
    final raw = _box?.get(_monthsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Month.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort(_compareMonths);
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
