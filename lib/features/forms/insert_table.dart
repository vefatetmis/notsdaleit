import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../editor/editor_state.dart';
import 'form_model.dart';

/// "Tablo ekle" akışı: satır/sütun sorar, gerekiyorsa serbest notun forma
/// dönüştürüleceğini bildirir, sonra editörün kancasını ([tableInserterProvider])
/// çağırır. Tablo notun **sonuna** eklenir.
Future<void> showInsertTableDialog(BuildContext context, WidgetRef ref) async {
  final insert = ref.read(tableInserterProvider);
  if (insert == null) return;
  final doc = ref.read(activeDocumentProvider);
  // Form olmayan (serbest/Quill) notta tablo eklemek notu forma çevirir:
  // yazı düz metne döner (kalın/italik gider), bu yüzden önceden söylenir.
  final needsConvert = doc == null || !isFormBody(doc.body);

  final result = await showDialog<(int, int)>(
    context: context,
    builder: (_) => _InsertTableDialog(warnConvert: needsConvert),
  );
  if (result == null) return;
  insert(result.$1, result.$2);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.t('Tablo notun sonuna eklendi',
            'Table added at the end of the note')),
      ));
  }
}

class _InsertTableDialog extends StatefulWidget {
  const _InsertTableDialog({required this.warnConvert});

  final bool warnConvert;

  @override
  State<_InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends State<_InsertTableDialog> {
  int _rows = 3;
  int _cols = 3;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return AlertDialog(
      title: Text(context.t('Tablo ekle', 'Add table')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Stepper(
            label: context.t('Satır', 'Rows'),
            value: _rows,
            min: 1,
            max: 20,
            onChanged: (v) => setState(() => _rows = v),
          ),
          const SizedBox(height: 6),
          _Stepper(
            label: context.t('Sütun', 'Columns'),
            value: _cols,
            min: 1,
            max: 8,
            onChanged: (v) => setState(() => _cols = v),
          ),
          const SizedBox(height: 14),
          _Preview(rows: _rows, cols: _cols),
          if (widget.warnConvert) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nd.hover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nd.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: nd.text2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t(
                        'Bu not tablo eklenince form notuna dönüşür: mevcut '
                            'yazın çizgili bir metin alanına taşınır, kalın/'
                            'italik gibi biçimler düz metne döner. Çizimler '
                            'olduğu gibi kalır.',
                        'Adding a table turns this note into a form note: your '
                            'current text moves into a ruled text area and '
                            'formatting like bold/italic becomes plain text. '
                            'Drawings are kept as they are.',
                      ),
                      style: TextStyle(
                          fontSize: 12.5, height: 1.35, color: nd.text2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('İptal', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((_rows, _cols)),
          child: Text(context.t('Ekle', 'Add')),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => IconButton(
          icon: Icon(icon, size: 20),
          onPressed: enabled ? onTap : null,
          visualDensity: VisualDensity.compact,
          color: nd.text2,
        );

    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        btn(Icons.remove, value > min, () => onChanged(value - 1)),
        SizedBox(
          width: 28,
          child: Text('$value',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        btn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }
}

/// Seçilen ölçünün küçük şematik önizlemesi (ilk satır başlık gibi koyu).
class _Preview extends StatelessWidget {
  const _Preview({required this.rows, required this.cols});

  final int rows;
  final int cols;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    // Çok satırlı tabloda önizleme kutusu büyümesin: en fazla 6 satır göster.
    final shown = rows > 6 ? 6 : rows;
    return Center(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: nd.borderStrong)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < shown; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < cols; c++)
                    Container(
                      width: 26,
                      height: 14,
                      decoration: BoxDecoration(
                        color: r == 0 ? nd.hover : null,
                        border: Border(
                          top: r > 0
                              ? BorderSide(color: nd.border)
                              : BorderSide.none,
                          left: c > 0
                              ? BorderSide(color: nd.border)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                ],
              ),
            if (rows > shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('…',
                    style: TextStyle(fontSize: 12, color: nd.text2)),
              ),
          ],
        ),
      ),
    );
  }
}
