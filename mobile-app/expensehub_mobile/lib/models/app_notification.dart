class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? groupId;
  final String? expenseId;
  final String? settlementId;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.groupId,
    this.expenseId,
    this.settlementId,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      groupId: json['groupId'],
      expenseId: json['expenseId'],
      settlementId: json['settlementId'],
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'] ?? false,
    );
  }
}
