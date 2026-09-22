import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Document scan → compress → Firebase Storage upload for expense receipts.
class ReceiptScanService {
  ReceiptScanService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in required to use receipts');
    }
    return user;
  }

  Future<List<String>> scanReceipts({int maxPages = 1}) async {
    final pictures = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      scannerSource: ScannerSource.cameraAndGallery,
    );
    return pictures ?? const [];
  }

  Future<File> compressImage(String path) async {
    final dir = await getTemporaryDirectory();
    final target = '${dir.path}/receipt_${_uuid.v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      return File(path);
    }
    return File(result.path);
  }

  Future<String> uploadReceipt({
    required String localPath,
    required String expenseId,
  }) async {
    final user = _requireUser;
    // Refresh ID token so Storage rules see a valid auth context.
    await user.getIdToken(true);

    final compressed = await compressImage(localPath);
    final ref = _storage.ref('users/${user.uid}/receipts/$expenseId.jpg');
    await ref.putFile(
      compressed,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteReceipt(String expenseId) async {
    final user = _requireUser;
    await user.getIdToken(true);
    try {
      await _storage.ref('users/${user.uid}/receipts/$expenseId.jpg').delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
