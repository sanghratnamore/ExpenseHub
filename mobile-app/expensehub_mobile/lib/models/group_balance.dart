class GroupBalance {
  final int userId;
  final String userName;
  final double totalPaid;
  final double totalShare;
  final double balance;
  final String status;


  GroupBalance({
    required this.userId,
    required this.userName,
    required this.totalPaid,
    required this.totalShare,
    required this.balance,
    required this.status,
  });


  factory GroupBalance.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupBalance(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] ?? '',
      totalPaid:
          (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalShare:
          (json['totalShare'] as num?)?.toDouble() ?? 0,
      balance:
          (json['balance'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'SETTLED',
    );
  }
}