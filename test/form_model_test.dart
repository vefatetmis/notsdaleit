import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/features/forms/form_model.dart';

/// Form gövdesinin **gidiş-dönüşü** (encode → decode).
///
/// Bu, uygulamadaki en riskli tek nokta: not içeriği `Documents.body`'de bu
/// biçimde durur ve **yedek, .ntdl, canlı paylaşım, şablon** hepsi aynı
/// dizeyi taşır. Bir blok tipi encode'da alan düşürürse ya da decode'da
/// varsayılana dönerse, kullanıcının yazdığı sessizce kaybolur — ekranda
/// hemen görünmeyebilir. Yeni blok tipi eklerken buraya da bir vaka ekle.
void main() {
  /// Gövdeyi kodlayıp yeniden çözer (kayıt/okuma turunun aynısı).
  FormDoc roundTrip(FormDoc doc) {
    final parsed = FormDoc.tryParse(doc.encode());
    expect(parsed, isNotNull, reason: 'encode edilen gövde çözülemedi');
    return parsed!;
  }

  test('başlık, alanlar ve checklist alanlarını korur', () {
    final doc = FormDoc([
      TitleBlock(text: 'Toplantı', counter: 'done'),
      FieldsBlock([
        FieldSpec(label: 'Tarih', value: '25 Tem'),
        FieldSpec(label: 'Yer', value: 'Ofis', flex: 2),
      ]),
      ChecklistBlock(
        items: [
          CheckItem(text: 'Sunum', done: true, trailing: 'Ali'),
          CheckItem(text: 'Rapor'),
        ],
        addLabel: 'Madde ekle',
      ),
    ]);

    final r = roundTrip(doc);
    expect((r.blocks[0] as TitleBlock).text, 'Toplantı');
    expect((r.blocks[0] as TitleBlock).counter, 'done');

    final fields = r.blocks[1] as FieldsBlock;
    expect(fields.fields[0].label, 'Tarih');
    expect(fields.fields[0].value, '25 Tem');
    expect(fields.fields[1].flex, 2);

    final check = r.blocks[2] as ChecklistBlock;
    expect(check.items.length, 2);
    expect(check.items[0].done, isTrue);
    expect(check.items[0].trailing, 'Ali');
    expect(check.items[1].done, isFalse);
    expect(check.addLabel, 'Madde ekle');
  });

  test('tablo satır/sütunlarını ve başlık bayrağını korur', () {
    final table = TableBlock(rows: [
      ['Ürün', 'Adet'],
      ['Kalem', '3'],
    ], header: false);
    final r = roundTrip(FormDoc([table]));
    final t = r.blocks.first as TableBlock;
    expect(t.rows, [
      ['Ürün', 'Adet'],
      ['Kalem', '3'],
    ]);
    expect(t.header, isFalse);
    expect(t.cols, 2);
  });

  test('görsel bloğu (eski biçim) alanlarını korur', () {
    // Yeni görseller ayrı tabloda (NoteImages) tutuluyor; bu blok yalnız eski
    // notlar için okunuyor — bozulursa o notlardaki fotoğraf kaybolur.
    final r = roundTrip(FormDoc([
      ImageBlock(file: '123.jpg', aspect: 1.25, caption: 'Tahta', width: 0.4),
    ]));
    final img = r.blocks.first as ImageBlock;
    expect(img.file, '123.jpg');
    expect(img.aspect, closeTo(1.25, 1e-6));
    expect(img.caption, 'Tahta');
    expect(img.width, closeTo(0.4, 1e-6));
  });

  test('alan biçimleri (kalın/italik/altı çizili) korunur', () {
    final doc = FormDoc([AreaBlock(value: 'metin')]);
    doc.toggleFmt('0.a', kFmtBold);
    doc.toggleFmt('0.a', kFmtUnderline);
    final r = roundTrip(doc);
    expect(r.hasFmt('0.a', kFmtBold), isTrue);
    expect(r.hasFmt('0.a', kFmtUnderline), isTrue);
    expect(r.hasFmt('0.a', kFmtItalic), isFalse);
  });

  test('hafta / cornell / saat blokları korunur', () {
    final r = roundTrip(FormDoc([
      WeekBlock([
        WeekDay(name: 'Pzt', meta: '3 iş', items: [CheckItem(text: 'Spor')]),
        WeekDay(name: 'Sal', faint: true, items: []),
      ]),
      CornellBlock(cues: 'ipucu', notes: 'not', summary: 'özet'),
      HoursBlock([HourRow(label: '09', value: 'Toplantı')]),
    ]));
    final week = r.blocks[0] as WeekBlock;
    expect(week.days[0].meta, '3 iş');
    expect(week.days[0].items.first.text, 'Spor');
    expect(week.days[1].faint, isTrue);

    final cornell = r.blocks[1] as CornellBlock;
    expect(cornell.notes, 'not');
    expect(cornell.summary, 'özet');

    expect((r.blocks[2] as HoursBlock).rows.first.value, 'Toplantı');
  });

  test('isFormBody yalnız gerçek form gövdesine evet der', () {
    expect(isFormBody(FormDoc([AreaBlock()]).encode()), isTrue);
    // Quill Delta (serbest not) form değildir.
    expect(isFormBody('[{"insert":"merhaba\\n"}]'), isFalse);
    expect(isFormBody(''), isFalse);
    expect(isFormBody('{bozuk'), isFalse);
    expect(isFormBody('{"ndform":2}'), isFalse);
  });

  test('bozuk gövde çökertmez, null döner', () {
    expect(FormDoc.tryParse('{bozuk'), isNull);
    expect(FormDoc.tryParse('[]'), isNull);
  });

  test('bilinmeyen blok tipi çökertmez', () {
    // İleride bir blok tipi kaldırılırsa eski notlar açılabilmeli.
    final parsed = FormDoc.tryParse('{"ndform":1,"blocks":[{"type":"zzz"}]}');
    expect(parsed, isNotNull);
    expect(parsed!.blocks.length, 1);
  });

  test('düz metin çıkarımı arama/önizleme için içerik verir', () {
    final doc = FormDoc([
      TitleBlock(text: 'Alışveriş'),
      ChecklistBlock(items: [CheckItem(text: 'Süt'), CheckItem(text: 'Ekmek')]),
    ]);
    final text = doc.plainText();
    expect(text, contains('Alışveriş'));
    expect(text, contains('Süt'));
    expect(text, contains('Ekmek'));
  });
}
