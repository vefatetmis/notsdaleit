import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/data/database/database.dart';

/// Şema geçişi (migration) testi.
///
/// Sahada çıkan hata: eski bir sürümden güncelleyen kullanıcıda `from < 9`
/// adımı `templates` tablosunu **bugünkü** tanımıyla (yani `page_background`
/// kolonu dâhil) kuruyor, hemen ardından `from < 10` adımı aynı kolonu
/// eklemeye çalışıp "duplicate column name" ile patlıyordu — uygulama hiç
/// açılmıyordu. Aynı tuzak `routines.remind_at` için de vardı.
///
/// Bu testler geçişlerin **idempotent** olduğunu doğrular. Bellek yerine
/// geçici DOSYA kullanılır; aynı veritabanını iki kez açabilmek gerekiyor
/// (birincisi şemayı kurar, ikincisi `onUpgrade`'i çalıştırır).
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nd_migration');
  });

  tearDown(() async {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// Güncel şemayı kurar, verilen tabloları düşürür ve `user_version`'ı
  /// [version] yapar → bir sonraki açılış `onUpgrade(from: version)` olur.
  Future<File> seedThenRewind(int version, List<String> drop) async {
    final file = File('${dir.path}/db_$version.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get(); // onCreate
    for (final table in drop) {
      await db.customStatement('DROP TABLE IF EXISTS "$table"');
    }
    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
    return file;
  }

  Future<List<String?>> columns(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info("$table")').get();
    return rows.map((r) => r.read<String?>('name')).toList();
  }

  test('v8 → güncel: templates yokken geçiş patlamaz', () async {
    // Sahadaki durum: kullanıcı v8'de, templates tablosu henüz yok.
    final file = await seedThenRewind(8, ['templates', 'tags', 'document_tags']);
    final db = AppDatabase.forTesting(NativeDatabase(file));

    // Açılış = onUpgrade(from: 8). Eski kodda burada
    // "duplicate column name: page_background" fırlıyordu.
    await db.customSelect('SELECT 1').get();

    final cols = await columns(db, 'templates');
    expect(cols.where((n) => n == 'page_background').length, 1);
    await db.close();
  });

  test('v5 → güncel: routines yokken geçiş patlamaz', () async {
    // routines v6'da eklendi, remind_at v8'de → aynı çifte-ekleme tuzağı.
    final file = await seedThenRewind(5, [
      'routines',
      'routine_checks',
      'folders',
      'templates',
      'tags',
      'document_tags',
    ]);
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();

    final cols = await columns(db, 'routines');
    expect(cols.where((n) => n == 'remind_at').length, 1);
    await db.close();
  });

  test('yarım kalmış geçiş: her şey yerindeyken tekrar çalışsa da bozulmaz',
      () async {
    // Migration yarıda kalıp user_version güncellenmezse açılışta yeniden
    // çalışır; tablolar/kolonlar zaten yerindeyken de hata vermemeli.
    final file = await seedThenRewind(8, const []);
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();
  });

  test('sıfırdan kurulum (onCreate) çalışıyor', () async {
    final file = File('${dir.path}/fresh.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    final cols = await columns(db, 'documents');
    expect(cols, contains('deleted_at'));
    expect(cols, contains('page_background'));
    await db.close();
  });
}
