import '../utils/json_utils.dart';

class GroupBalance {
  final String userId;
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
      userId: JsonUtils.parseId(json['userId']),
      userName: JsonUtils.parseString(json['userName']),
      totalPaid: JsonUtils.parseDouble(json['totalPaid']),
      totalShare: JsonUtils.parseDouble(json['totalShare']),
      balance: JsonUtils.parseDouble(json['balance']),
      status: JsonUtils.parseString(
        json['status'],
        fallback: 'SETTLED',
      ),
    );
  }
}