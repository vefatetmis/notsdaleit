import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/collab/collab_config.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';

/// Canlı ortak not senkronu.
///
/// Tasarım: senkron katmanı **drift (yerel) ile Supabase arasında** durur.
/// UI her zamanki gibi drift akışlarından beslenir; bu dosya yerel değişimi
/// sunucuya, sunucudan geleni yerele taşır.
/// - Çizimler: ekleme-temelli olaylar → gerçek zamanlı, çakışmasız.
///   Yankı/çift kayıt `Strokes.remoteId` (uuid) ile önlenir.
/// - Metin/başlık/kağıt: debounce'lu tam güncelleme, son yazan kazanır (LWW).

enum CollabStatus { connecting, live, offline }

/// Açık oturumun bağlantı durumu (null = aktif oturum yok). Üst bar rozeti okur.
final collabStatusProvider = StateProvider<CollabStatus?>((ref) => null);

/// Uzaktan gelen metin güncellemesi — açık editör dinler ve (kullanıcı o an
/// yazmıyorsa) Quill controller'a uygular.
class RemoteNoteUpdate {
  RemoteNoteUpdate(this.docId, this.title, this.body, this.seq);
  final int docId;
  final String title;
  final String body;
  final int seq; // her olayda artar → dinleyici kesin tetiklenir
}

final remoteNoteUpdateProvider =
    StateProvider<RemoteNoteUpdate?>((ref) => null);

/// Canlı paylaşım sona erdi (sahibi durdurdu ya da not silindi) — açık editör
/// tek seferlik bilgilendirir. Her olayda artar.
final collabEndedProvider = StateProvider<int>((ref) => 0);

/// Aktif belge paylaşımlıysa oturumu açık tutar (editör build'de watch eder).
final collabSessionProvider = Provider.autoDispose<CollabSession?>((ref) {
  if (!CollabConfig.enabled) return null;
  final key = ref.watch(activeDocumentProvider.select((d) =>
      d == null || d.type != 'not' || d.sharedId == null
          ? null
          : (d.id, d.sharedId!)));
  if (key == null) return null;
  final session = CollabSession(ref, key.$1, key.$2);
  ref.onDispose(session.close);
  return session;
});

final collabServiceProvider = Provider<CollabService>((ref) {
  return CollabService(ref);
});

// ─────────────────────────── Servis (paylaş / katıl) ───────────────────────────

class CollabService {
  CollabService(this._ref);

  final Ref _ref;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  /// Notu canlı paylaşıma açar; katılım kodunu döndürür.
  Future<String> shareNote(Document doc) async {
    await ensureSignedIn();
    final res = await _client.rpc('create_shared_note', params: {
      'p_title': doc.title,
      'p_body': doc.body,
      'p_page_size': doc.pageSize,
      'p_page_color': doc.pageColor,
      'p_page_count': doc.pageCount ?? 1,
    });
    final map = (res is List ? res.first : res) as Map<String, dynamic>;
    final sharedId = map['id'] as String;
    final code = map['share_code'] as String;
    await _ref
        .read(documentRepositoryProvider)
        .setShared(id: doc.id, sharedId: sharedId, shareCode: code);
    // Mevcut çizimler oturum başlayınca otomatik gönderilir (remoteId boş
    // olanları oturum push eder) — burada ayrıca göndermiyoruz (tek yol).
    return code;
  }

  /// Katılım koduyla ortak nota katılır; yerel belge id'sini döndürür.
  Future<int> joinByCode(String code) async {
    await ensureSignedIn();
    final res = await _client
        .rpc('join_note', params: {'p_code': code.trim().toUpperCase()});
    final map = (res is List ? res.first : res) as Map<String, dynamic>;
    final sharedId = map['id'] as String;

    final docRepo = _ref.read(documentRepositoryProvider);
    final existing = await docRepo.getBySharedId(sharedId);
    if (existing != null) return existing.id;

    final id = await docRepo.insertNote(
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      folder: 'Kişisel',
      pageSize: (map['page_size'] as String?) ?? 'a4',
      pageColor: (map['page_color'] as String?) ?? 'beyaz',
      pageCount: (map['page_count'] as num?)?.toInt() ?? 1,
    );
    await docRepo.setShared(
        id: id, sharedId: sharedId, shareCode: map['share_code'] as String);
    // Çizimler not açılınca oturumun ilk eşitlemesiyle gelir.
    return id;
  }

  /// Canlı paylaşımı bırakır. Sahipse sunucudaki notu siler (kod geçersizleşir),
  /// üyeyse yalnızca kendi üyeliğini siler. Her durumda yerelde kişisel nota
  /// döner (çizim ve metin yerelde kalır).
  Future<void> unshare(Document doc) async {
    final sid = doc.sharedId;
    if (sid == null) return;
    try {
      await ensureSignedIn();
      final uid = _client.auth.currentUser?.id;
      final row = await _client
          .from('shared_notes')
          .select('created_by')
          .eq('id', sid)
          .maybeSingle();
      final isOwner = row != null && row['created_by'] == uid;
      if (isOwner) {
        await _client.from('shared_notes').delete().eq('id', sid);
      } else if (uid != null) {
        await _client
            .from('note_members')
            .delete()
            .eq('note_id', sid)
            .eq('user_id', uid);
      }
    } catch (_) {
      // Ağ hatası olsa da yerelde paylaşımı kaldırıyoruz (kullanıcı isteği).
    }
    await _ref.read(documentRepositoryProvider).clearShared(doc.id);
  }
}

// ─────────────────────────── Oturum (gerçek zamanlı) ───────────────────────────

class CollabSession {
  CollabSession(this._ref, this.docId, this.sharedId) {
    _start();
  }

  final Ref _ref;
  final int docId;
  final String sharedId;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  RealtimeChannel? _channel;
  StreamSubscription<List<Stroke>>? _strokesSub;
  StreamSubscription<Document?>? _docSub;
  Timer? _pushNoteTimer;
  bool _closed = false;
  bool _ending = false; // paylaşım sonlanıyor → toplu silmeleri yok say
  int _seq = 0;

  // Yankı / çift kayıt önleme durumu.
  Set<String> _knownRemoteIds = {};
  final Set<String> _pendingPushIds = {}; // sunucuya gönderilmekte olan uuid'ler
  final Set<String> _skipDeletePush = {}; // uzaktan silindi → geri gönderme
  final Set<int> _pushingLocal = {}; // gönderimi süren yerel çizgi id'leri

  // Son eşitlenen not içeriği (fark yoksa push edilmez).
  String? _lastTitle;
  String? _lastBody;
  String? _lastColor;
  int? _lastPageCount;

  void _setStatus(CollabStatus s) {
    if (_closed) return;
    try {
      _ref.read(collabStatusProvider.notifier).state = s;
    } catch (_) {}
  }

  Future<void> _start() async {
    _setStatus(CollabStatus.connecting);
    try {
      if (_client.auth.currentSession == null) {
        await _client.auth.signInAnonymously();
      }
    } catch (_) {
      _setStatus(CollabStatus.offline);
      // Kanal aboneliği yine de kurulur; soket bağlanınca 'subscribed' gelir
      // ve ilk eşitleme orada tekrar denenir.
    }
    if (_closed) return;

    _channel = _client
        .channel('note-$sharedId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'shared_strokes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'note_id',
            value: sharedId,
          ),
          callback: (payload) => _onRemoteStrokeInsert(payload.newRecord),
        )
        .onPostgresChanges(
          // DELETE olayında eski kayıtta yalnızca birincil anahtar bulunur;
          // note_id filtresi çalışmaz. Filtresiz dinleyip yerelde eşleştiririz.
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'shared_strokes',
          callback: (payload) => _onRemoteStrokeDelete(payload.oldRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'shared_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sharedId,
          ),
          callback: (payload) => _onRemoteNoteUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          // Sahibi paylaşımı durdurdu → not silindi. Filtresiz dinleyip PK
          // eşleştiririz (DELETE payload'unda yalnız birincil anahtar var).
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'shared_notes',
          callback: (payload) {
            if (payload.oldRecord['id'] == sharedId) _handleEnded();
          },
        )
        .subscribe((status, [error]) {
      if (_closed) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        _setStatus(CollabStatus.live);
        // Bağlantı (yeniden) kuruldu → arada kaçanları eşitle.
        _initialSync();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.timedOut) {
        _setStatus(CollabStatus.offline);
      }
    });

    _startLocalWatches();
  }

  /// Sunucu ile tam karşılaştırmalı eşitleme (bağlanınca ve yeniden bağlanınca).
  Future<void> _initialSync() async {
    try {
      final docRepo = _ref.read(documentRepositoryProvider);
      final drawRepo = _ref.read(drawingRepositoryProvider);

      // 1) Not gövdesi — son yazan kazanır.
      final row = await _client
          .from('shared_notes')
          .select()
          .eq('id', sharedId)
          .maybeSingle();
      if (_closed) return;
      if (row == null) {
        // Not sunucuda yok (sahibi paylaşımı durdurdu) → kişisel nota dön.
        await _handleEnded();
        return;
      }
      final local = await docRepo.getById(docId);
      if (_closed || local == null) return;
      final remoteUpdatedAt =
          DateTime.tryParse((row['updated_at'] as String?) ?? '')?.toLocal();
      final remoteIsOurs = row['updated_by'] == _uid;
      if (remoteUpdatedAt != null &&
          remoteUpdatedAt.isAfter(local.updatedAt) &&
          !remoteIsOurs) {
        await _applyRemoteNote(row);
      } else if (local.body != (row['body'] as String? ?? '') ||
          local.title != (row['title'] as String? ?? '')) {
        await _pushNote(local);
      } else {
        _lastTitle = local.title;
        _lastBody = local.body;
        _lastColor = local.pageColor;
        _lastPageCount = local.pageCount ?? 1;
      }

      // 2) Çizimler — iki yönlü fark.
      final remoteRows =
          await _client.from('shared_strokes').select().eq('note_id', sharedId);
      if (_closed) return;
      final localStrokes = await drawRepo.getStrokes(docId);
      final localRemoteIds = <String>{
        for (final s in localStrokes)
          if (s.remoteId != null) s.remoteId!,
      };
      final serverIds = <String>{};
      for (final r in (remoteRows as List)) {
        final m = (r as Map).cast<String, dynamic>();
        final rid = m['id'] as String;
        serverIds.add(rid);
        if (!localRemoteIds.contains(rid) && !_pendingPushIds.contains(rid)) {
          _knownRemoteIds.add(rid);
          await drawRepo.addStroke(
            docId: docId,
            page: (m['page'] as num?)?.toInt() ?? 0,
            tool: (m['tool'] as String?) ?? 'kalem',
            color: (m['color'] as num?)?.toInt() ?? 0xFF262626,
            width: (m['width'] as num?)?.toDouble() ?? 5,
            pointsJson: (m['points'] as String?) ?? '[]',
            remoteId: rid,
          );
        }
      }
      // Yerelde olup sunucuda olmayan (uzaktan silinmiş) → yerelden kaldır.
      for (final s in localStrokes) {
        final rid = s.remoteId;
        if (rid != null &&
            !serverIds.contains(rid) &&
            !_pendingPushIds.contains(rid)) {
          _skipDeletePush.add(rid);
          await drawRepo.deleteByRemoteId(docId, rid);
        }
      }
      // remoteId'si boş yereller yerel izleyici tarafından push edilir.
    } catch (_) {
      // Ağ hatası — kanal durumu zaten offline'ı gösterecek.
    }
  }

  // ── Uzaktan gelenler ──

  Future<void> _onRemoteStrokeInsert(Map<String, dynamic> rec) async {
    if (_closed) return;
    final rid = rec['id'] as String?;
    if (rid == null) return;
    if (_knownRemoteIds.contains(rid) || _pendingPushIds.contains(rid)) return;
    _knownRemoteIds.add(rid);
    await _ref.read(drawingRepositoryProvider).addStroke(
          docId: docId,
          page: (rec['page'] as num?)?.toInt() ?? 0,
          tool: (rec['tool'] as String?) ?? 'kalem',
          color: (rec['color'] as num?)?.toInt() ?? 0xFF262626,
          width: (rec['width'] as num?)?.toDouble() ?? 5,
          pointsJson: (rec['points'] as String?) ?? '[]',
          remoteId: rid,
        );
  }

  Future<void> _onRemoteStrokeDelete(Map<String, dynamic> rec) async {
    if (_closed || _ending) return; // paylaşım sonlanırken toplu silmeyi atla
    final rid = rec['id'] as String?;
    if (rid == null || !_knownRemoteIds.contains(rid)) return;
    _skipDeletePush.add(rid);
    await _ref.read(drawingRepositoryProvider).deleteByRemoteId(docId, rid);
  }

  Future<void> _onRemoteNoteUpdate(Map<String, dynamic> rec) async {
    if (_closed) return;
    if (rec['updated_by'] == _uid) return; // kendi yankımız
    await _applyRemoteNote(rec);
  }

  Future<void> _applyRemoteNote(Map<String, dynamic> rec) async {
    final title = (rec['title'] as String?) ?? '';
    final body = (rec['body'] as String?) ?? '';
    final color = (rec['page_color'] as String?) ?? 'beyaz';
    final pageCount = (rec['page_count'] as num?)?.toInt() ?? 1;
    _lastTitle = title;
    _lastBody = body;
    _lastColor = color;
    _lastPageCount = pageCount;
    await _ref.read(documentRepositoryProvider).applyRemote(
          id: docId,
          title: title,
          body: body,
          pageColor: color,
          pageCount: pageCount,
        );
    if (_closed) return;
    try {
      _ref.read(remoteNoteUpdateProvider.notifier).state =
          RemoteNoteUpdate(docId, title, body, _seq++);
    } catch (_) {}
  }

  /// Paylaşım sona erdi: yerelde kişisel nota dön + tek seferlik bilgilendir.
  /// sharedId null olunca collabSessionProvider bu oturumu dispose eder.
  Future<void> _handleEnded() async {
    if (_closed || _ending) return;
    _ending = true;
    try {
      await _ref.read(documentRepositoryProvider).clearShared(docId);
    } catch (_) {}
    try {
      _ref.read(collabEndedProvider.notifier).state++;
    } catch (_) {}
  }

  // ── Yerel değişiklikler ──

  void _startLocalWatches() {
    // Çizimler: fark alarak sunucuya it (yeni) / sil (kaybolan).
    _strokesSub =
        _ref.read(drawingRepositoryProvider).watchStrokes(docId).listen((rows) {
      if (_closed) return;
      final current = <String>{};
      final currentLocalIds = <int>{};
      for (final s in rows) {
        currentLocalIds.add(s.id);
        final rid = s.remoteId;
        if (rid != null) {
          current.add(rid);
        } else if (!_pushingLocal.contains(s.id)) {
          _pushingLocal.add(s.id);
          _pushStroke(s);
        }
      }
      for (final gone in _knownRemoteIds.difference(current)) {
        if (_skipDeletePush.remove(gone)) continue;
        _deleteRemoteStroke(gone);
      }
      _knownRemoteIds = current;
      _pushingLocal.removeWhere((id) => !currentLocalIds.contains(id));
    });

    // Not gövdesi/başlık/kağıt: debounce'lu push.
    _docSub =
        _ref.read(documentRepositoryProvider).watchById(docId).listen((doc) {
      if (_closed || doc == null) return;
      if (doc.title == _lastTitle &&
          doc.body == _lastBody &&
          doc.pageColor == _lastColor &&
          (doc.pageCount ?? 1) == _lastPageCount) {
        return;
      }
      _pushNoteTimer?.cancel();
      _pushNoteTimer = Timer(const Duration(milliseconds: 600), () {
        if (!_closed) _pushNote(doc);
      });
    });
  }

  Future<void> _pushStroke(Stroke s) async {
    final rid = _genUuid();
    _pendingPushIds.add(rid);
    try {
      // Önce sunucuya yaz; başarılıysa yerelde işaretle. (Ters sıra, gönderim
      // başarısız olduğunda ilk eşitlemenin çizgiyi 'uzaktan silinmiş' sanıp
      // yerelden silmesine yol açardı.)
      await _client.from('shared_strokes').insert({
        'id': rid,
        'note_id': sharedId,
        'page': s.page,
        'tool': s.tool,
        'color': s.color,
        'width': s.width,
        'points': s.points,
        'created_by': _uid,
      });
      _knownRemoteIds.add(rid);
      await _ref
          .read(drawingRepositoryProvider)
          .setStrokeRemoteId(s.id, rid);
    } catch (_) {
      // Gönderilemedi (çevrimdışı vb.) — remoteId boş kaldı; yeniden
      // bağlanınca tekrar denenir.
      _pushingLocal.remove(s.id);
    } finally {
      _pendingPushIds.remove(rid);
    }
  }

  Future<void> _deleteRemoteStroke(String rid) async {
    try {
      await _client.from('shared_strokes').delete().eq('id', rid);
    } catch (_) {}
  }

  Future<void> _pushNote(Document doc) async {
    _lastTitle = doc.title;
    _lastBody = doc.body;
    _lastColor = doc.pageColor;
    _lastPageCount = doc.pageCount ?? 1;
    try {
      await _client.from('shared_notes').update({
        'title': doc.title,
        'body': doc.body,
        'page_color': doc.pageColor,
        'page_count': doc.pageCount ?? 1,
        'updated_by': _uid,
      }).eq('id', sharedId);
    } catch (_) {
      // Çevrimdışı — yeniden bağlanınca ilk eşitleme halleder.
    }
  }

  void close() {
    _closed = true;
    _pushNoteTimer?.cancel();
    _strokesSub?.cancel();
    _docSub?.cancel();
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    try {
      _ref.read(collabStatusProvider.notifier).state = null;
    } catch (_) {}
  }
}

// ─────────────────────────── Yardımcılar ───────────────────────────

final Random _rnd = Random.secure();

String _genUuid() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // sürüm 4
  b[8] = (b[8] & 0x3f) | 0x80; // varyant
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
