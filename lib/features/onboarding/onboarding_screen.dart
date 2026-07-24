import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/collab/collab_config.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/nd_colors.dart';
import '../auth/auth_service.dart';
import '../auth/auth_ui.dart';

/// İlk açılış tanıtımı — uygulamadaki her şeyi (şablonlar, yaz&çiz, PDF,
/// rutinler&hatırlatıcılar) tanıtan bir tur; sonda e-posta ile giriş/kayıt.
/// Bittiğinde [onboardingDoneProvider] işaretlenir.
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

  Future<void> _signIn() async {
    final ok = await showSignInSheet(context, ref);
    if (ok && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final slides = <_Slide>[
      _Slide(
        art: const _WelcomeArt(),
        title: 'notsdaleit',
        desc: context.t('Notlar, PDF, çizim ve şablonlar — tek uygulamada.',
            'Notes, PDF, drawing and templates — all in one app.'),
      ),
      _Slide(
        art: const _TemplatesArt(),
        title: context.t('Hazır şablonlar', 'Ready-made templates'),
        desc: context.t(
            'Yapılacaklar, günlük plan, haftalık ızgara, Cornell, toplantı… '
                'Aç, doldur, hazırsın.',
            'To-do, daily plan, weekly grid, Cornell, meeting notes… '
                'Open, fill in, done.'),
      ),
      _Slide(
        art: const _WriteDrawArt(),
        title: context.t('Yaz ve çiz', 'Write & draw'),
        desc: context.t(
            'Aynı sayfada biçimli yazı yaz, kalemle çiz. Aa ile yazıya, '
                'kalemle çizime geç.',
            'Write formatted text and draw with a pen on the same page. '
                'Tap Aa for text, the pens to draw.'),
      ),
      _Slide(
        art: const _PdfArt(),
        title: context.t('PDF üzerine işaretle', 'Annotate PDFs'),
        desc: context.t('PDF içe aktar, sayfaların üstüne kalemle not al.',
            'Import a PDF and mark it up with the pen.'),
      ),
      _Slide(
        art: const _RoutinesArt(),
        title: context.t('Rutinler & hatırlatıcılar', 'Routines & reminders'),
        desc: context.t(
            'Alışkanlıklarını takip et, seri yap 🔥; görevlerine ve '
                'rutinlerine tam zamanında bildirim al.',
            'Track habits and build streaks 🔥; get reminders for tasks and '
                'routines right on time.'),
      ),
      // Giriş arayüzü kapalıyken bu slayt hiç gösterilmez (bkz. kAuthEnabled).
      if (CollabConfig.enabled && kAuthEnabled)
        _Slide(
          art: const _SyncArt(),
          title: context.t('Her cihazda yanında', 'On every device'),
          desc: context.t(
              'E-posta ile giriş yap, notların ve çizimlerin cihazlar arası '
                  'senkronlansın. Parola yok — sadece e-postana gelen kod.',
              'Sign in with email so your notes and drawings sync across '
                  'devices. No password — just a code sent to your email.'),
          isSignIn: true,
        ),
    ];
    final isLast = _page == slides.length - 1;
    final slide = slides[_page];

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
                itemCount: slides.length,
                itemBuilder: (context, i) => _SlideView(slide: slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: slide.isSignIn
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _signIn,
                            icon: const Icon(Icons.mail_outline_rounded,
                                size: 18),
                            label: Text(context.t(
                                'Giriş yap / Kaydol', 'Sign in / Sign up')),
                            style: _btnStyle(nd),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            context.t('Şimdilik geç', 'Maybe later'),
                            style: TextStyle(color: nd.text2),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
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
                        style: _btnStyle(nd),
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

  ButtonStyle _btnStyle(NdColors nd) => FilledButton.styleFrom(
        backgroundColor: nd.accent,
        foregroundColor: nd.accentFg,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
}

class _Slide {
  const _Slide({
    required this.art,
    required this.title,
    required this.desc,
    this.isSignIn = false,
  });
  final Widget art;
  final String title;
  final String desc;
  final bool isSignIn;
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
          SizedBox(height: 190, child: Center(child: slide.art)),
          const SizedBox(height: 34),
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

// ── Slayt görselleri (küçük illüstrasyon kartları) ────────────────────

const _cream = Color(0xFFF6ECCE);
const _mint = Color(0xFFE8F0E6);
const _ink = Color(0xFF1E1E1C);
const _line = Color(0xFFDCD8CC);
const _muted = Color(0xFFA6A49D);

class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Image.asset('assets/icon/app_icon.png',
          width: 128, height: 128, fit: BoxFit.cover),
    );
  }
}

/// Küçük kâğıt kartı iskeleti (başlık çubuğu + satırlar).
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.child,
    this.color = Colors.white,
    this.width = 150,
    this.height = 176,
    this.rotate = 0,
  });
  final Widget child;
  final Color color;
  final double width;
  final double height;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: child,
      ),
    );
  }
}

Widget _bar(double w, {double h = 5, Color? c}) => Container(
      width: w,
      height: h,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: c ?? _line, borderRadius: BorderRadius.circular(3)),
    );

Widget _checkRow({bool done = false, double w = 74}) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: done ? _ink : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: done ? _ink : _muted, width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check, size: 9, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            width: w,
            height: 4.5,
            decoration: BoxDecoration(
                color: _line, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );

class _TemplatesArt extends StatelessWidget {
  const _TemplatesArt();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-58, 8),
          child: _MiniCard(
            color: _mint,
            width: 118,
            height: 150,
            rotate: -0.09,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(46, h: 7, c: _muted),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          height: 60,
                          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: _line),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(52, -6),
          child: _MiniCard(
            width: 130,
            height: 162,
            rotate: 0.06,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(70, h: 8, c: _ink),
                const SizedBox(height: 6),
                _checkRow(done: true, w: 66),
                _checkRow(done: true, w: 54),
                _checkRow(w: 70),
                _checkRow(w: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WriteDrawArt extends StatelessWidget {
  const _WriteDrawArt();
  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      width: 168,
      height: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(96, h: 8, c: _ink),
          const SizedBox(height: 4),
          _bar(132),
          _bar(120),
          _bar(70),
          const SizedBox(height: 6),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _ScribblePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF3B82C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(4, size.height * 0.6);
    path.cubicTo(size.width * 0.25, -6, size.width * 0.4, size.height + 4,
        size.width * 0.62, size.height * 0.5);
    path.cubicTo(size.width * 0.78, size.height * 0.1, size.width * 0.9,
        size.height * 0.2, size.width - 6, size.height * 0.7);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PdfArt extends StatelessWidget {
  const _PdfArt();
  @override
  Widget build(BuildContext context) {
    return _MiniCard(
      width: 150,
      height: 178,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFE24B4A),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('PDF',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          _bar(120),
          _bar(128),
          _bar(96),
          _bar(120),
          _bar(60),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 46,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFF0A500), width: 2.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutinesArt extends StatelessWidget {
  const _RoutinesArt();
  @override
  Widget build(BuildContext context) {
    Widget row(String label, bool done, String streak) => Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done ? const Color(0xFF1D9E75) : Colors.transparent,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: done ? const Color(0xFF1D9E75) : _muted, width: 1.6),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Container(
                  width: 62,
                  height: 6,
                  decoration: BoxDecoration(
                      color: _line, borderRadius: BorderRadius.circular(3))),
              const Spacer(),
              Text('🔥$streak',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return SizedBox(
      width: 210,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row('', true, '7'),
          row('', true, '3'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 18, color: Color(0xFFBA7517)),
                const SizedBox(width: 10),
                Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE4D296),
                        borderRadius: BorderRadius.circular(3))),
                const Spacer(),
                const Text('09:00',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF854F0B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncArt extends StatelessWidget {
  const _SyncArt();
  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    Widget device(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: nd.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: nd.borderStrong, width: 1.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(w * 0.5, h: 5, c: nd.border),
                _bar(w * 0.72, h: 4, c: nd.border),
                _bar(w * 0.6, h: 4, c: nd.border),
              ],
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        device(74, 108),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.sync_rounded, size: 30, color: nd.accent),
        ),
        device(96, 132),
      ],
    );
  }
}
