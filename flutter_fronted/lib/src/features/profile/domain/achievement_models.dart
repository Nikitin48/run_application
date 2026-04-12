class AchievementItem {
  const AchievementItem({
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.xp,
    required this.sortOrder,
    required this.isUnlocked,
    required this.unlockedAt,
  });

  final String code;
  final String title;
  final String description;
  final String category;
  final String iconKey;
  final int xp;
  final int sortOrder;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}

class AchievementsOverview {
  const AchievementsOverview({
    required this.profileXp,
    required this.profileLevel,
    required this.items,
  });

  final int profileXp;
  final int profileLevel;
  final List<AchievementItem> items;
}
