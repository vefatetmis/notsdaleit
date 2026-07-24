import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';

/// Paletten renk seçmek için ortak palet (rengarenk kalem + ayarlardaki kalem
/// renkleri aynı listeyi kullanır → tutarlılık).
const List<Color> kPalette = [
  Color(0xFF262626), Color(0xFF6B7280), Color(0xFFB91C1C), Color(0xFFE0533D),
  Color(0xFFF0B429), Color(0xFF16A34A), Color(0xFF0D9488), Color(0xFF2563EB),
  Color(0xFF4A6CF7), Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFF000000),
  Color(0xFFFFFFFF), Color(0xFFF87171), Color(0xFFFB923C), Color(0xFFFACC15),
  Color(0xFF4ADE80), Color(0xFF22D3EE), Color(0xFF60A5FA), Color(0xFFA78BFA),
  Color(0xFFF472B6), Color(0xFF9CA3AF),
];

/// Tutarlı tasarımlı renk seçme penceresi. Seçilen rengi döndürür (yoksa null).
Future<Color?> showColorGridDialog(BuildContext context, {Color? current}) {
  final nd = context.nd;
  return showDialog<Color>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: nd.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: nd.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('Renk seç', 'Pick a colour'),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: nd.text)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in kPalette)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: current == c
                              ? nd.text
                              : Colors.black.withValues(alpha: 0.15),
                          width: current == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
