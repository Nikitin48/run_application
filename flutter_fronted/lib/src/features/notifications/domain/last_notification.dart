class LastNotification {
  const LastNotification({
    required this.kind,
    required this.attackerUserId,
    required this.runId,
    required this.stolenAreaM2,
    required this.createdAt,
  });

  final String kind;
  final String? attackerUserId;
  final String? runId;
  final double stolenAreaM2;
  final DateTime createdAt;
}


