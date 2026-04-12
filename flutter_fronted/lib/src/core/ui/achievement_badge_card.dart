import 'package:flutter/material.dart';
import 'package:run_application/l10n/app_localizations.dart';

class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.xp,
    this.isUnlocked = true,
    this.compact = false,
  });

  final String title;
  final String description;
  final String iconKey;
  final int xp;
  final bool isUnlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = isUnlocked
        ? achievementPaletteForXp(xp)
        : lockedAchievementPalette();
    final iconSize = compact ? 18.0 : 22.0;
    final badgeSize = compact ? 42.0 : 50.0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.background, palette.background.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: palette.glow.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.accent, palette.accentSecondary],
                  ),
                  boxShadow: [
                    if (isUnlocked)
                      BoxShadow(
                        color: palette.glow.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Icon(
                  achievementIconForKey(iconKey),
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BadgePill(
                          label: '+$xp XP',
                          background: palette.pillBackground,
                          foreground: palette.pillForeground,
                        ),
                        _BadgePill(
                          label: achievementTierLabel(l10n, xp),
                          background: palette.pillBackground.withValues(alpha: 0.8),
                          foreground: palette.pillForeground,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AchievementPalette {
  const AchievementPalette({
    required this.background,
    required this.border,
    required this.accent,
    required this.accentSecondary,
    required this.glow,
    required this.pillBackground,
    required this.pillForeground,
  });

  final Color background;
  final Color border;
  final Color accent;
  final Color accentSecondary;
  final Color glow;
  final Color pillBackground;
  final Color pillForeground;
}

AchievementPalette achievementPaletteForXp(int xp) {
  if (xp >= 1000) {
    return const AchievementPalette(
      background: Color(0xFF22183B),
      border: Color(0xFFE6D6FF),
      accent: Color(0xFFC89BFF),
      accentSecondary: Color(0xFF7C4DFF),
      glow: Color(0xFFB388FF),
      pillBackground: Color(0x33F3E8FF),
      pillForeground: Color(0xFFF3E8FF),
    );
  }
  if (xp >= 500) {
    return const AchievementPalette(
      background: Color(0xFF2C2410),
      border: Color(0xFFFFE08A),
      accent: Color(0xFFFFD54F),
      accentSecondary: Color(0xFFFFA000),
      glow: Color(0xFFFFCA28),
      pillBackground: Color(0x33FFF3CD),
      pillForeground: Color(0xFFFFF3CD),
    );
  }
  if (xp >= 250) {
    return const AchievementPalette(
      background: Color(0xFF1E2630),
      border: Color(0xFFD8E4F0),
      accent: Color(0xFF9AAFC7),
      accentSecondary: Color(0xFF6B8098),
      glow: Color(0xFFB0BEC5),
      pillBackground: Color(0x33E5EEF6),
      pillForeground: Color(0xFFEAF3FA),
    );
  }
  return const AchievementPalette(
    background: Color(0xFF2B201B),
    border: Color(0xFFE2B091),
    accent: Color(0xFFD8895B),
    accentSecondary: Color(0xFF9B5E3C),
    glow: Color(0xFFC7835C),
    pillBackground: Color(0x33F6E0D2),
    pillForeground: Color(0xFFFBE9DF),
  );
}

String achievementTierLabel(AppLocalizations l10n, int xp) {
  if (xp >= 1000) return l10n.achievementTierLegendary;
  if (xp >= 500) return l10n.achievementTierRare;
  if (xp >= 250) return l10n.achievementTierAdvanced;
  return l10n.achievementTierBase;
}

AchievementPalette lockedAchievementPalette() {
  return const AchievementPalette(
    background: Color(0xFF23262C),
    border: Color(0xFF50555F),
    accent: Color(0xFF70757F),
    accentSecondary: Color(0xFF555A63),
    glow: Color(0x00000000),
    pillBackground: Color(0x334A4F57),
    pillForeground: Color(0xFFE1E3E7),
  );
}

IconData achievementIconForKey(String iconKey) {
  switch (iconKey) {
    case 'run_count':
      return Icons.directions_run;
    case 'distance_single':
      return Icons.route_outlined;
    case 'distance_total':
      return Icons.timeline;
    case 'capture_single':
      return Icons.crop_square_rounded;
    case 'capture_total':
      return Icons.public;
    case 'captures_count':
      return Icons.flag_outlined;
    case 'victims':
      return Icons.gps_fixed;
    case 'owned_area':
      return Icons.map_outlined;
    case 'level_up':
      return Icons.military_tech;
    default:
      return Icons.emoji_events_outlined;
  }
}
