import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/sell_category.dart';
import '../domain/sell_models.dart';

/// Local-first drafts: `<appDocs>/sell_drafts/<id>/draft.json` plus copies of
/// the picked photos in the same folder. 14-day expiry, at most 4 drafts.
/// Every method swallows storage errors — a failing disk must never break
/// the form.
class SellDraftStore {
  SellDraftStore._();
  static final SellDraftStore instance = SellDraftStore._();

  static const Duration expiry = Duration(days: 14);
  static const int maxDrafts = 4;

  Directory? _root;

  Future<Directory> _rootDir() async {
    final existing = _root;
    if (existing != null) return existing;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'sell_drafts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  Future<Directory> folderFor(String draftId) async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, draftId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a picked file into the draft folder and returns the new path.
  Future<String> adoptFile(String draftId, String sourcePath, String localId) async {
    try {
      final dir = await folderFor(draftId);
      final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final target = p.join(dir.path, '$localId$ext');
      await File(sourcePath).copy(target);
      return target;
    } catch (_) {
      return sourcePath;
    }
  }

  Future<void> _queue = Future<void>.value();

  /// Saves are serialised so two overlapping writes never share the .tmp file.
  Future<void> save(SellDraft draft) {
    final next = _queue.then((_) => _save(draft)).catchError((_) {});
    _queue = next;
    return next;
  }

  Future<void> _save(SellDraft draft) async {
    try {
      final dir = await folderFor(draft.id);
      final file = File(p.join(dir.path, 'draft.json'));
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(draft.toJson()), flush: true);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  Future<SellDraft?> load(String draftId) async {
    try {
      final root = await _rootDir();
      final file = File(p.join(root.path, draftId, 'draft.json'));
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final draft = SellDraft.fromJson(json);
      if (draft == null) return null;
      // Drop media whose local copy has gone missing.
      final media = <SellMediaItem>[];
      for (final m in draft.media) {
        if (m.mediaId != null || await File(m.localPath).exists()) media.add(m);
      }
      return SellDraft(
        id: draft.id,
        category: draft.category,
        step: draft.step,
        values: draft.values,
        media: media,
        idempotencyKey: draft.idempotencyKey,
        updatedAt: draft.updatedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Newest first; expired and extra drafts are deleted on the way.
  Future<List<SellDraft>> all() async {
    final drafts = <SellDraft>[];
    try {
      final root = await _rootDir();
      await for (final entity in root.list()) {
        if (entity is! Directory) continue;
        final d = await load(p.basename(entity.path));
        if (d == null) {
          await _deleteDir(entity);
          continue;
        }
        if (DateTime.now().difference(d.updatedAt) > expiry) {
          await _deleteDir(entity);
          continue;
        }
        drafts.add(d);
      }
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      while (drafts.length > maxDrafts) {
        final old = drafts.removeLast();
        await delete(old.id);
      }
    } catch (_) {}
    return drafts;
  }

  Future<SellDraft?> latestFor(SellCategory c) async {
    final list = await all();
    for (final d in list) {
      if (d.category == c) return d;
    }
    return null;
  }

  Future<void> delete(String draftId) async {
    try {
      final root = await _rootDir();
      await _deleteDir(Directory(p.join(root.path, draftId)));
    } catch (_) {}
  }

  Future<void> _deleteDir(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
