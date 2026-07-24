import 'dart:convert';

/// Form-not modeli: şablon sayfaları (Yapılacaklar, Günlük Plan, Cornell…)
/// Claude Design'daki gibi **yapılandırılmış form** olarak saklanır ve native
/// widget'larla çizilir (Quill'e gömülmez — dokunma/odak sorunları yaşanmaz).
///
/// Gövde biçimi: `{"ndform":1,"blocks":[{...}...]}` — Documents.body'de durur;
/// kaydetme, canlı paylaşım (LWW), .ntdl ve şablon kaydetme otomatik taşır.
/// Boş/serbest notlar eskisi gibi Quill Delta listesi kullanır.

/// Gövde bir form mu? (hızlı kontrol — Quill yoluna girmeden önce bakılır)
bool isFormBody(String body) {
  final t = body.trimLeft();
  if (!t.startsWith('{')) return false;
  try {
    final j = jsonDecode(body);
    return j is Map && j['ndform'] == 1;
  } catch (_) {
    return false;
  }
}

/// Alan biçim bayrakları: kalın · italik · altı çizili. Yazı boyutu BİLEREK
/// yok — satır yükseklikleri (`form_layout`) sabit boyutlara göre hesaplandığı
/// için boyut değişimi ekran/PDF/sayfalama senkronunu bozar (bkz. CLAUDE.md).
const String kFmtBold = 'b';
const String kFmtItalic = 'i';
const String kFmtUnderline = 'u';

class FormDoc {
  FormDoc(this.blocks, {Map<String, String>? styles})
      : styles = styles ?? <String, String>{};

  final List<FormBlock> blocks;

  /// Alan biçimleri: alan anahtarı ('0.t', '2.i3'…) → bayrak dizesi ('bu' =
  /// kalın + altı çizili). Anahtarlar `FormPage`'in controller anahtarlarıyla
  /// birebir aynıdır; böylece blok sınıflarına dokunmadan biçim taşınır.
  /// Eski form notlarında bu harita boştur → görünüm değişmez.
  final Map<String, String> styles;

  bool hasFmt(String key, String flag) => (styles[key] ?? '').contains(flag);

  /// Bir alanın bir biçim bayrağını açar/kapatır.
  void toggleFmt(String key, String flag) {
    final cur = styles[key] ?? '';
    final String s;
    if (cur.contains(flag)) {
      s = cur.replaceAll(flag, '');
    } else {
      s = ((cur + flag).split('')..sort()).join();
    }
    if (s.isEmpty) {
      styles.remove(key);
    } else {
      styles[key] = s;
    }
  }

  /// Bir bloğun tüm alan biçimlerini siler. Blok içinde satır/sütun eklenip
  /// silinince index'ler kaydığından biçimlerin yanlış hücreye geçmemesi için
  /// (tablo düzenlemesinde) çağrılır.
  void clearStylesForBlock(int block) =>
      styles.removeWhere((k, _) => k.startsWith('$block.'));

  static FormDoc? tryParse(String body) {
    try {
      final j = jsonDecode(body);
      if (j is! Map || j['ndform'] != 1) return null;
      final raw = j['styles'];
      return FormDoc(
        [
          for (final b in (j['blocks'] as List? ?? const []))
            FormBlock.fromJson((b as Map).cast<String, dynamic>()),
        ],
        styles: raw is Map
            ? {
                for (final e in raw.entries)
                  if (e.value is String && (e.value as String).isNotEmpty)
                    e.key.toString(): e.value as String,
              }
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode({
        'ndform': 1,
        'blocks': [for (final b in blocks) b.toJson()],
        if (styles.isNotEmpty) 'styles': styles,
      });

  /// Önizleme/arama için düz metin.
  String plainText() {
    final sb = StringBuffer();
    for (final b in blocks) {
      b.collectText(sb);
    }
    return sb.toString().trim();
  }

  /// Başlık sayaçları için: (işaretli, toplam) kutucuk sayısı.
  (int, int) checkCounts() {
    var done = 0, total = 0;
    for (final b in blocks) {
      if (b is ChecklistBlock) {
        for (final it in b.items) {
          total++;
          if (it.done) done++;
        }
      }
      if (b is WeekBlock) {
        for (final d in b.days) {
          for (final it in d.items) {
            total++;
            if (it.done) done++;
          }
        }
      }
    }
    return (done, total);
  }
}

/// Tek kutucuklu satır (checklist / hafta hücresi).
class CheckItem {
  CheckItem({this.text = '', this.done = false, this.trailing = ''});
  String text;
  bool done;
  String trailing; // adet ('1') / kişi ('Kim?') gibi sağ küçük alan

  factory CheckItem.fromJson(Map<String, dynamic> j) => CheckItem(
        text: (j['t'] as String?) ?? '',
        done: j['d'] == 1,
        trailing: (j['x'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (text.isNotEmpty) 't': text,
        if (done) 'd': 1,
        if (trailing.isNotEmpty) 'x': trailing,
      };
}

/// Etiket + altı çizili alan (fields satırındaki tek sütun).
class FieldSpec {
  FieldSpec({this.label = '', this.hint = '', this.value = '', this.flex = 1});
  String label;
  String hint;
  String value;
  int flex;

  factory FieldSpec.fromJson(Map<String, dynamic> j) => FieldSpec(
        label: (j['l'] as String?) ?? '',
        hint: (j['h'] as String?) ?? '',
        value: (j['v'] as String?) ?? '',
        flex: (j['f'] as int?) ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (label.isNotEmpty) 'l': label,
        if (hint.isNotEmpty) 'h': hint,
        if (value.isNotEmpty) 'v': value,
        if (flex != 1) 'f': flex,
      };
}

class WeekDay {
  WeekDay({required this.name, this.meta = '', this.faint = false,
      required this.items});
  final String name;
  String meta;
  final bool faint;
  final List<CheckItem> items;

  factory WeekDay.fromJson(Map<String, dynamic> j) => WeekDay(
        name: (j['n'] as String?) ?? '',
        meta: (j['m'] as String?) ?? '',
        faint: j['f'] == 1,
        items: [
          for (final it in (j['i'] as List? ?? const []))
            CheckItem.fromJson((it as Map).cast<String, dynamic>()),
        ],
      );

  Map<String, dynamic> toJson() => {
        'n': name,
        if (meta.isNotEmpty) 'm': meta,
        if (faint) 'f': 1,
        'i': [for (final it in items) it.toJson()],
      };
}

class HourRow {
  HourRow({required this.label, this.value = ''});
  final String label;
  String value;

  factory HourRow.fromJson(Map<String, dynamic> j) =>
      HourRow(label: (j['h'] as String?) ?? '', value: (j['v'] as String?) ?? '');

  Map<String, dynamic> toJson() =>
      {'h': label, if (value.isNotEmpty) 'v': value};
}

/// Form blokları. JSON'da `type` alanıyla ayrışır.
sealed class FormBlock {
  const FormBlock();

  factory FormBlock.fromJson(Map<String, dynamic> j) {
    switch (j['type']) {
      case 'title':
        return TitleBlock(
          text: (j['t'] as String?) ?? '',
          hint: (j['h'] as String?) ?? '',
          counter: (j['c'] as String?) ?? '',
          unit: (j['u'] as String?) ?? '',
        );
      case 'fields':
        return FieldsBlock([
          for (final f in (j['f'] as List? ?? const []))
            FieldSpec.fromJson((f as Map).cast<String, dynamic>()),
        ]);
      case 'label':
        return LabelBlock((j['t'] as String?) ?? '');
      case 'check':
        return ChecklistBlock(
          items: [
            for (final it in (j['i'] as List? ?? const []))
              CheckItem.fromJson((it as Map).cast<String, dynamic>()),
          ],
          trailingHint: (j['th'] as String?) ?? '',
          trailingWidth: (j['tw'] as num?)?.toDouble() ?? 0,
          addLabel: (j['a'] as String?) ?? '',
        );
      case 'num':
        return NumberedBlock(
            [for (final s in (j['i'] as List? ?? const [])) s as String? ?? '']);
      case 'area':
        return AreaBlock(
          value: (j['v'] as String?) ?? '',
          hint: (j['h'] as String?) ?? '',
          minLines: (j['n'] as int?) ?? 4,
          lined: j['ln'] != 0,
        );
      case 'mood':
        return MoodBlock(
          label: (j['t'] as String?) ?? '',
          count: (j['n'] as int?) ?? 5,
          selected: (j['s'] as int?) ?? -1,
        );
      case 'hours':
        return HoursBlock([
          for (final r in (j['r'] as List? ?? const []))
            HourRow.fromJson((r as Map).cast<String, dynamic>()),
        ]);
      case 'week':
        return WeekBlock([
          for (final d in (j['d'] as List? ?? const []))
            WeekDay.fromJson((d as Map).cast<String, dynamic>()),
        ]);
      case 'cornell':
        return CornellBlock(
          cuesLabel: (j['cl'] as String?) ?? '',
          notesLabel: (j['nl'] as String?) ?? '',
          summaryLabel: (j['sl'] as String?) ?? '',
          cues: (j['c'] as String?) ?? '',
          notes: (j['n'] as String?) ?? '',
          summary: (j['s'] as String?) ?? '',
        );
      case 'sketch':
        return SketchBlock((j['h'] as num?)?.toDouble() ?? 120);
      case 'table':
        return TableBlock(
          rows: [
            for (final r in (j['r'] as List? ?? const []))
              [for (final c in (r as List? ?? const [])) (c as String?) ?? ''],
          ],
          header: j['hd'] != 0,
        );
      default:
        return LabelBlock('');
    }
  }

  Map<String, dynamic> toJson();

  void collectText(StringBuffer sb) {}
}

class TitleBlock extends FormBlock {
  TitleBlock({this.text = '', this.hint = '', this.counter = '', this.unit = ''});
  String text;
  final String hint;
  final String counter; // '' | 'done' (n/m) | 'count' (n + unit)
  final String unit;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'title',
        if (text.isNotEmpty) 't': text,
        if (hint.isNotEmpty) 'h': hint,
        if (counter.isNotEmpty) 'c': counter,
        if (unit.isNotEmpty) 'u': unit,
      };

  @override
  void collectText(StringBuffer sb) => sb.writeln(text);
}

class FieldsBlock extends FormBlock {
  FieldsBlock(this.fields);
  final List<FieldSpec> fields;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'fields', 'f': [for (final f in fields) f.toJson()]};

  @override
  void collectText(StringBuffer sb) {
    for (final f in fields) {
      if (f.value.isNotEmpty) sb.writeln('${f.label} ${f.value}'.trim());
    }
  }
}

class LabelBlock extends FormBlock {
  LabelBlock(this.text);
  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': 'label', 't': text};

  @override
  void collectText(StringBuffer sb) => sb.writeln(text);
}

class ChecklistBlock extends FormBlock {
  ChecklistBlock({
    required this.items,
    this.trailingHint = '',
    this.trailingWidth = 0,
    this.addLabel = '',
  });
  final List<CheckItem> items;
  final String trailingHint; // '1' (adet) / 'Kim?' — boşsa sağ alan yok
  final double trailingWidth;
  final String addLabel; // boşsa "satır ekle" düğmesi yok

  @override
  Map<String, dynamic> toJson() => {
        'type': 'check',
        'i': [for (final it in items) it.toJson()],
        if (trailingHint.isNotEmpty) 'th': trailingHint,
        if (trailingWidth > 0) 'tw': trailingWidth,
        if (addLabel.isNotEmpty) 'a': addLabel,
      };

  @override
  void collectText(StringBuffer sb) {
    for (final it in items) {
      if (it.text.isNotEmpty) sb.writeln(it.text);
    }
  }
}

class NumberedBlock extends FormBlock {
  NumberedBlock(this.items);
  final List<String> items;

  @override
  Map<String, dynamic> toJson() => {'type': 'num', 'i': items};

  @override
  void collectText(StringBuffer sb) {
    for (final s in items) {
      if (s.isNotEmpty) sb.writeln(s);
    }
  }
}

class AreaBlock extends FormBlock {
  AreaBlock({this.value = '', this.hint = '', this.minLines = 4, this.lined = true});
  String value;
  final String hint;
  final int minLines;
  final bool lined;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'area',
        if (value.isNotEmpty) 'v': value,
        if (hint.isNotEmpty) 'h': hint,
        'n': minLines,
        if (!lined) 'ln': 0,
      };

  @override
  void collectText(StringBuffer sb) => sb.writeln(value);
}

class MoodBlock extends FormBlock {
  MoodBlock({this.label = '', this.count = 5, this.selected = -1});
  final String label;
  final int count;
  int selected;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'mood', 't': label, 'n': count, 's': selected};
}

class HoursBlock extends FormBlock {
  HoursBlock(this.rows);
  final List<HourRow> rows;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'hours', 'r': [for (final r in rows) r.toJson()]};

  @override
  void collectText(StringBuffer sb) {
    for (final r in rows) {
      if (r.value.isNotEmpty) sb.writeln('${r.label} ${r.value}');
    }
  }
}

class WeekBlock extends FormBlock {
  WeekBlock(this.days);
  final List<WeekDay> days;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'week', 'd': [for (final d in days) d.toJson()]};

  @override
  void collectText(StringBuffer sb) {
    for (final d in days) {
      for (final it in d.items) {
        if (it.text.isNotEmpty) sb.writeln(it.text);
      }
    }
  }
}

class CornellBlock extends FormBlock {
  CornellBlock({
    this.cuesLabel = '',
    this.notesLabel = '',
    this.summaryLabel = '',
    this.cues = '',
    this.notes = '',
    this.summary = '',
  });
  final String cuesLabel;
  final String notesLabel;
  final String summaryLabel;
  String cues;
  String notes;
  String summary;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cornell',
        'cl': cuesLabel,
        'nl': notesLabel,
        'sl': summaryLabel,
        if (cues.isNotEmpty) 'c': cues,
        if (notes.isNotEmpty) 'n': notes,
        if (summary.isNotEmpty) 's': summary,
      };

  @override
  void collectText(StringBuffer sb) {
    sb.writeln(cues);
    sb.writeln(notes);
    sb.writeln(summary);
  }
}

class SketchBlock extends FormBlock {
  SketchBlock(this.height);
  final double height;

  @override
  Map<String, dynamic> toJson() => {'type': 'sketch', 'h': height};
}

/// Elle eklenen tablo: hücreli ızgara. [rows] dikdörtgen tutulur (tüm satırlar
/// aynı sütun sayısında); [header] açıksa ilk satır başlık gibi çizilir.
/// Satırlar sayfalamada tek tek bölünebildiği için her satır kendi çerçevesini
/// çizer (bir sonraki sayfaya taşan tablo yine kapalı görünür).
class TableBlock extends FormBlock {
  TableBlock({required this.rows, this.header = true}) {
    _normalize();
  }

  /// [r] satır × [c] sütunluk boş tablo.
  factory TableBlock.empty({required int r, required int c}) => TableBlock(
        rows: [for (var i = 0; i < r; i++) [for (var k = 0; k < c; k++) '']],
      );

  final List<List<String>> rows;
  bool header;

  int get cols => rows.isEmpty ? 0 : rows.first.length;

  /// Bozuk/elle düzenlenmiş JSON'a karşı: en az 1×1, tüm satırlar eşit uzunlukta.
  void _normalize() {
    if (rows.isEmpty) rows.add(['']);
    var n = 0;
    for (final r in rows) {
      if (r.length > n) n = r.length;
    }
    if (n == 0) n = 1;
    for (final r in rows) {
      while (r.length < n) {
        r.add('');
      }
    }
  }

  // Index'ler dışarıdan (menü kancası) geldiği için hepsi sınırlanır.

  void addRow([int? at]) => rows.insert((at ?? rows.length).clamp(0, rows.length),
      [for (var i = 0; i < cols; i++) '']);

  void removeRow(int r) {
    if (rows.length > 1 && r >= 0 && r < rows.length) rows.removeAt(r);
  }

  void addColumn([int? at]) {
    final i = (at ?? cols).clamp(0, cols);
    for (final r in rows) {
      r.insert(i, '');
    }
  }

  void removeColumn(int c) {
    if (cols <= 1 || c < 0 || c >= cols) return;
    for (final r in rows) {
      r.removeAt(c);
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'table',
        'r': rows,
        if (!header) 'hd': 0,
      };

  @override
  void collectText(StringBuffer sb) {
    for (final r in rows) {
      final line = r.where((c) => c.isNotEmpty).join(' ');
      if (line.isNotEmpty) sb.writeln(line);
    }
  }
}
