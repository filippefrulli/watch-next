import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/pages/language_page.dart';
import 'package:watch_next/utils/app_colors.dart';

/// First screen a brand-new user sees. It conveys the app's core hook —
/// conversational, streaming-aware discovery — before the language/region/
/// streaming setup, so the value proposition lands at the top of the funnel.
class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const LanguagePage(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut))
              .animate(animation),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),
                    // App glyph
                    DelayedDisplay(
                      delay: const Duration(milliseconds: 80),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [context.appColors.accent, context.appColors.accentDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset('assets/icon_transparent.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    DelayedDisplay(
                      delay: const Duration(milliseconds: 160),
                      child: Text(
                        'intro_title'.tr(),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DelayedDisplay(
                      delay: const Duration(milliseconds: 240),
                      child: Text(
                        'intro_subtitle'.tr(),
                        style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _feature(context, Icons.chat_bubble_outline, 'intro_feature_1'.tr(), 320),
                    const SizedBox(height: 20),
                    _feature(context, Icons.live_tv_outlined, 'intro_feature_2'.tr(), 400),
                    const SizedBox(height: 20),
                    _feature(context, Icons.bookmark_outline, 'intro_feature_3'.tr(), 480),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            DelayedDisplay(
              delay: const Duration(milliseconds: 560),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.appColors.accent, context.appColors.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _continue(context),
                    child: Center(
                      child: Text(
                        'intro_cta'.tr().toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String label, int delayMs) {
    return DelayedDisplay(
      delay: Duration(milliseconds: delayMs),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.appColors.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
