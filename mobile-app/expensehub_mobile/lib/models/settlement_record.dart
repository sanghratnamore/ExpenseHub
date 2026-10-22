class SettlementRecord {
  final int id;
  final int groupId;
  final String paidByName;
  final String paidToName;
  final double amount;
  final String settlementDate;
  final String message;


  SettlementRecord({
    required this.id,
    required this.groupId,
    required this.paidByName,
    required this.paidToName,
    required this.amount,
    required this.settlementDate,
    required this.message,
  });


  factory SettlementRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      groupId:
          (json['groupId'] as num?)?.toInt() ?? 0,
      paidByName: json['paidByName'] ?? '',
      paidToName: json['paidToName'] ?? '',
      amount:
          (json['amount'] as num?)?.toDouble() ?? 0,
      settlementDate:
          json['settlementDate'] ?? '',
      message: json['message'] ?? '',
    );
  }
}