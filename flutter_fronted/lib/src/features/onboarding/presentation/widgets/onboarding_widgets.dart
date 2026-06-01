import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/onboarding_slide.dart';

class OnboardingSlideStyle {
  const OnboardingSlideStyle({
    required this.icon,
    required this.accent,
    required this.secondaryAccent,
    required this.metricLabel,
  });

  final IconData icon;
  final Color accent;
  final Color secondaryAccent;
  final String metricLabel;

  Color get ctaForeground {
    return accent == AppColors.green0DF ? AppColors.background : Colors.white;
  }
}

OnboardingSlideStyle onboardingSlideStyle(OnboardingSlide slide) {
  return switch (slide.visual) {
    OnboardingVisual.route => const OnboardingSlideStyle(
      icon: Icons.route,
      accent: AppColors.blue3399,
      secondaryAccent: AppColors.purple8C3,
      metricLabel: '+ территория',
    ),
    OnboardingVisual.shield => const OnboardingSlideStyle(
      icon: Icons.shield_outlined,
      accent: AppColors.green0DF,
      secondaryAccent: AppColors.blue66B2,
      metricLabel: 'защита 6ч',
    ),
    OnboardingVisual.contest => const OnboardingSlideStyle(
      icon: Icons.emoji_events_outlined,
      accent: AppColors.purple8C3,
      secondaryAccent: AppColors.blue3399,
      metricLabel: 'спорная зона',
    ),
  };
}

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({
    super.key,
    required this.slide,
    required this.compact,
  });

  final OnboardingSlide slide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = onboardingSlideStyle(slide);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(height: compact ? 16 : 34),
        Expanded(
          flex: compact ? 9 : 10,
          child: Center(
            child: _HeroCard(slide: slide, style: style, compact: compact),
          ),
        ),
        SizedBox(height: compact ? 18 : 28),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: style.accent.withValues(alpha: 0.34)),
            ),
            child: Text(
              slide.eyebrow,
              style: textTheme.labelSmall?.copyWith(
                color: style.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            slide.title,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.06,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            slide.body,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.text,
              height: 1.42,
            ),
          ),
        ),
        SizedBox(height: compact ? 10 : 22),
      ],
    );
  }
}

class OnboardingBrandMark extends StatelessWidget {
  const OnboardingBrandMark({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Icon(Icons.directions_run, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Text(
          'GeoRun',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class OnboardingPageDots extends StatelessWidget {
  const OnboardingPageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.color,
  });

  final int count;
  final int currentIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: selected ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.78, -0.82),
          radius: 1.15,
          colors: [
            accent.withValues(alpha: 0.28),
            AppColors.background.withValues(alpha: 0.82),
            AppColors.background,
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: CustomPaint(painter: _BackgroundOrbitPainter(accent: accent)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.slide,
    required this.style,
    required this.compact,
  });

  final OnboardingSlide slide;
  final OnboardingSlideStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 270.0 : 340.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            boxShadow: [
              BoxShadow(
                color: style.accent.withValues(alpha: 0.24),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    accent: style.accent,
                    secondaryAccent: style.secondaryAccent,
                    visual: slide.visual,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: _GlassIcon(icon: style.icon, color: style.accent),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: _MetricPill(
                  label: style.metricLabel,
                  color: style.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.accent,
    required this.secondaryAccent,
    required this.visual,
  });

  final Color accent;
  final Color secondaryAccent;
  final OnboardingVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    const step = 34.0;
    for (var x = -step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + 38, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.34),
      size.shortestSide * 0.32,
      glowPaint,
    );

    switch (visual) {
      case OnboardingVisual.route:
        _paintRoute(canvas, size);
      case OnboardingVisual.shield:
        _paintShield(canvas, size);
      case OnboardingVisual.contest:
        _paintContest(canvas, size);
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.25, size.height * 0.58),
      Offset(size.width * 0.52, size.height * 0.25),
      Offset(size.width * 0.78, size.height * 0.46),
      Offset(size.width * 0.52, size.height * 0.79),
    ];
    final territory = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..quadraticBezierTo(
        size.width * 0.27,
        size.height * 0.31,
        points[1].dx,
        points[1].dy,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.22,
        points[2].dx,
        points[2].dy,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.78,
        points[3].dx,
        points[3].dy,
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.82,
        points[0].dx,
        points[0].dy,
      );
    _drawTerritory(canvas, territory, accent);

    final runnerPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 4.5, runnerPaint);
    }
  }

  void _paintShield(Canvas canvas, Size size) {
    final territory = Path()
      ..moveTo(size.width * 0.2, size.height * 0.66)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.38,
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.66,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.36,
        size.width * 0.83,
        size.height * 0.72,
        size.width * 0.57,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.9,
        size.width * 0.21,
        size.height * 0.81,
        size.width * 0.2,
        size.height * 0.66,
      );
    _drawTerritory(canvas, territory, accent);

    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.31)
      ..lineTo(size.width * 0.68, size.height * 0.39)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.62,
        size.width * 0.59,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.79,
      )
      ..cubicTo(
        size.width * 0.41,
        size.height * 0.72,
        size.width * 0.34,
        size.height * 0.62,
        size.width * 0.32,
        size.height * 0.39,
      )
      ..close();
    canvas.drawPath(
      shield,
      Paint()..color = AppColors.background.withValues(alpha: 0.62),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );

    final smallPathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawLine(
      Offset(size.width * 0.69, size.height * 0.76),
      Offset(size.width * 0.78, size.height * 0.82),
      smallPathPaint,
    );
  }

  void _paintContest(Canvas canvas, Size size) {
    final first = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.43, size.height * 0.56),
          width: size.width * 0.54,
          height: size.height * 0.46,
        ),
      );
    final second = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.62, size.height * 0.5),
          width: size.width * 0.54,
          height: size.height * 0.48,
        ),
      );
    _drawTerritory(canvas, first, secondaryAccent);
    _drawTerritory(canvas, second, accent);

    final contestRect = Rect.fromCenter(
      center: Offset(size.width * 0.53, size.height * 0.53),
      width: size.width * 0.22,
      height: size.height * 0.36,
    );
    canvas.drawOval(
      contestRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            secondaryAccent.withValues(alpha: 0.82),
            accent.withValues(alpha: 0.82),
          ],
        ).createShader(contestRect),
    );
    canvas.drawOval(
      contestRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  void _drawTerritory(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return accent != oldDelegate.accent ||
        secondaryAccent != oldDelegate.secondaryAccent ||
        visual != oldDelegate.visual;
  }
}

class _BackgroundOrbitPainter extends CustomPainter {
  const _BackgroundOrbitPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.045);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.15, size.height * 0.2),
          width: 260.0 + i * 82,
          height: 180.0 + i * 62,
        ),
        math.pi * 0.12,
        math.pi * 1.3,
        false,
        paint,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.86),
      110,
      Paint()
        ..color = accent.withValues(alpha: 0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 46),
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundOrbitPainter oldDelegate) {
    return accent != oldDelegate.accent;
  }
}
