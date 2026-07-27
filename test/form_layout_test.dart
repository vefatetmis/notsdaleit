import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/features/forms/form_layout.dart';
import 'package:notsdaleit/features/forms/form_model.dart';

/// Form sayfalama ve tablo sınırları.
///
/// Sayfalama, sahada en çok hata çıkan yer oldu (içerik sayfa kartının altında
/// kırpılıyordu, tablo satırları kayboluyordu). Ekran ve PDF **aynı** hesabı
/// kullandığı için buradaki bir kayma iki tarafta birden bozulma demek.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // TextPainter ölçümü için

  const pageSizes = ['a4', 'kare', 'yatay', 'telefon'];

  group('tablo sınırları', () {
    test('her sayfa boyutu için makul ve sabit', () {
      for (final size in pageSizes) {
        expect(maxTableRows(size), greaterThanOrEqualTo(3),
            reason: '$size satır sınırı çok düşük');
        expect(maxTableCols(size), greaterThanOrEqualTo(2),
            reason: '$size sütun sınırı çok düşük');
      }
      // Cihazda ölçülen değerler (bkz. CLAUDE.md) — kazara değişirse yakala.
      expect(maxTableRows('a4'), 12);
      expect(maxTableRows('telefon'), 14);
      expect(maxTableRows('kare'), 8);
      expect(maxTableRows('yatay'), 8);
    });

    test('bilinmeyen boyut A4 gibi davranır', () {
      expect(maxTableRows('serbest'), maxTableRows('a4'));
      expect(maxTableCols(null), maxTableCols('a4'));
    });

    test('geniş sayfa daha çok sütun alır', () {
      expect(maxTableCols('yatay'), greaterThan(maxTableCols('telefon')));
    });
  });

  group('sayfalama', () {
    /// Bir formun kaç sayfa tuttuğu.
    int pages(FormDoc doc, String size) => formNaturalPageCount(doc, size);

    test('kısa içerik tek sayfa', () {
      final doc = FormDoc([
        TitleBlock(text: 'Kısa'),
        AreaBlock(value: 'birkaç kelime'),
      ]);
      expect(pages(doc, 'a4'), 1);
    });

    test('uzun checklist sayfa sayısını büyütür', () {
      final short = FormDoc([
        ChecklistBlock(items: [for (var i = 0; i < 5; i++) CheckItem()]),
      ]);
      final long = FormDoc([
        ChecklistBlock(items: [for (var i = 0; i < 120; i++) CheckItem()]),
      ]);
      expect(pages(short, 'a4'), 1);
      expect(pages(long, 'a4'), greaterThan(1),
          reason: 'içerik taşıyorsa sayfa açılmalı — yoksa kırpılır');
    });

    test('sayfa sayısı içerikle birlikte artar (azalmaz)', () {
      var previous = 0;
      for (final n in [10, 60, 140, 260]) {
        final doc = FormDoc([
          ChecklistBlock(items: [for (var i = 0; i < n; i++) CheckItem()]),
        ]);
        final p = pages(doc, 'a4');
        expect(p, greaterThanOrEqualTo(previous),
            reason: 'içerik arttıkça sayfa azalmamalı');
        previous = p;
      }
    });

    test('satırlı bloklar satır satır bölünür (blok topluca atlamaz)', () {
      // Sığan satırlar ilk sayfada kalmalı: eskiden tüm liste sonraki sayfaya
      // atlayıp ilk sayfayı boş bırakıyordu.
      final doc = FormDoc([
        ChecklistBlock(items: [for (var i = 0; i < 60; i++) CheckItem()]),
      ]);
      final m = formMetrics('a4');
      final layout = paginateForm(doc, m.virtualW, m.contentH, m.pageSkip,
          editable: true);
      final firstPageUnits = layout.units.where((u) => u.page == 0).length;
      expect(firstPageUnits, greaterThan(1),
          reason: 'ilk sayfa boş kalmamalı');
      expect(layout.pages, greaterThan(1));
    });

    test('dar sayfa aynı içerikte daha çok sayfa tutar', () {
      final doc = FormDoc([
        ChecklistBlock(items: [for (var i = 0; i < 80; i++) CheckItem()]),
      ]);
      expect(pages(doc, 'kare'), greaterThanOrEqualTo(pages(doc, 'a4')));
    });

    test('boş form en az bir sayfa', () {
      expect(pages(FormDoc([]), 'a4'), 1);
    });
  });

  group('tablo ölçüsü', () {
    test('satır sayısı arttıkça tablo yükselir', () {
      final m = formMetrics('a4');
      final small = TableBlock.empty(r: 2, c: 3);
      final big = TableBlock.empty(r: 10, c: 3);
      final hSmall = measureFormBlock(small, m.virtualW, editable: false);
      final hBig = measureFormBlock(big, m.virtualW, editable: false);
      expect(hBig, greaterThan(hSmall));
    });

    test('hücre iç genişliği sütun sayısıyla daralır', () {
      final m = formMetrics('a4');
      expect(tableCellInnerWidth(m.virtualW, 6),
          lessThan(tableCellInnerWidth(m.virtualW, 2)));
    });
  });
}
