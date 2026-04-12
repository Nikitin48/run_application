import 'package:flutter/material.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileAchievementsSummaryCard extends StatelessWidget {
  const ProfileAchievementsSummaryCard({
    super.key,
    required this.profileLevel,
    required this.profileXp,
    required this.unlockedCount,
    required this.totalCount,
  });

  final int profileLevel;
  final int profileXp;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue1F8C.withValues(alpha: 0.24),
            AppColors.purple8C3.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondPrimary.withValues(alpha: 0.36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.blue1F8C,
                child: Icon(Icons.military_tech_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.achievementsCollectionTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.achievementsCollectionSummary(
                        unlockedCount,
                        profileLevel,
                        profileXp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                icon: Icons.workspace_premium_outlined,
                label: '${l10n.profileLevelLabel}: $profileLevel',
              ),
              _SummaryPill(
                icon: Icons.bolt_outlined,
                label: '${l10n.profileXpLabel}: $profileXp XP',
              ),
              _SummaryPill(
                icon: Icons.emoji_events_outlined,
                label: '$unlockedCount / $totalCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
