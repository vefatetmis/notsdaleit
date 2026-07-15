import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';

/// Kısa tanıtım ekranı (ilk açılışta). Bittiğinde [onboardingDoneProvider]
/// işaretlenir ve uygulamaya geçilir.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingDoneProvider.notifier).complete();

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final pages = <_Slide>[
      _Slide(
        image: true,
        icon: Icons.auto_awesome,
        title: 'notsdaleit',
        desc: context.t('Notlar, PDF ve çizim — tek uygulamada.',
            'Notes, PDF and drawing — all in one app.'),
      ),
      _Slide(
        icon: Icons.edit_note,
        title: context.t('Yaz ve çiz', 'Write & draw'),
        desc: context.t(
            'Aynı sayfada biçimli yazı yaz, kalemle çiz. Araç çubuğundaki '
                'Aa ile yazıya, kalemle çizime geç.',
            'Write formatted text and draw with a pen on the same page. '
                'Tap Aa for text, the pens to draw.'),
      ),
      _Slide(
        icon: Icons.picture_as_pdf_outlined,
        title: context.t('PDF üzerine işaretle', 'Annotate PDFs'),
        desc: context.t(
            'PDF içe aktar, sayfaların üstüne kalemle not al.',
            'Import a PDF and mark it up with the pen.'),
      ),
      _Slide(
        icon: Icons.calendar_today_outlined,
        title: context.t('Takvim & hatırlatıcı', 'Calendar & reminders'),
        desc: context.t(
            'Görev ekle, saat seç, tam zamanında bildirim al.',
            'Add tasks, pick a time, and get reminders right on time.'),
      ),
    ];
    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: nd.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(context.t('Geç', 'Skip'),
                      style: TextStyle(color: nd.text2)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (context, i) => _SlideView(slide: pages[i]),
              ),
            ),
            // Sayfa göstergeleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? nd.accent : nd.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: nd.accent,
                    foregroundColor: nd.accentFg,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: Text(isLast
                      ? context.t('Başla', 'Get started')
                      : context.t('İleri', 'Next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.desc,
    this.image = false,
  });
  final IconData icon;
  final String title;
  final String desc;
  final bool image;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/icon/app_icon.png',
                  width: 120, height: 120, fit: BoxFit.cover),
            )
          else
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: nd.card,
                shape: BoxShape.circle,
                border: Border.all(color: nd.border),
              ),
              child: Icon(slide.icon, size: 48, color: nd.text),
            ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            slide.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: nd.text2),
          ),
        ],
      ),
    );
  }
}
