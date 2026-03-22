class LastNotification {
  const LastNotification({
    required this.id,
    required this.kind,
    required this.attackerUserId,
    required this.attackerDisplayName,
    required this.runId,
    required this.stolenAreaM2,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String? attackerUserId;
  final String? attackerDisplayName;
  final String? runId;
  final double stolenAreaM2;
  final DateTime createdAt;
}


