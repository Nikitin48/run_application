class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    required this.isBanned,
    required this.ownedAreaM2,
    required this.createdAt,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isBanned;
  final double ownedAreaM2;
  final DateTime createdAt;
}

class AdminUserActionResult {
  const AdminUserActionResult({
    required this.user,
    required this.revokedSessionsCount,
    required this.deletedTerritoriesCount,
  });

  final AdminUser user;
  final int revokedSessionsCount;
  final int deletedTerritoriesCount;
}
