import '../utils/json_utils.dart';

class SettlementRecord {
  final String id;
  final String groupId;
  final String paidByName;
  final String paidToName;
  final double amount;
  final String settlementDate;
  final String settledAt;
  final String message;

  SettlementRecord({
    required this.id,
    required this.groupId,
    required this.paidByName,
    required this.paidToName,
    required this.amount,
    required this.settlementDate,
    required this.settledAt,
    required this.message,
  });

  factory SettlementRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementRecord(
      id: JsonUtils.parseId(json['id']),
      groupId: JsonUtils.parseId(json['groupId']),
      paidByName: JsonUtils.parseString(json['paidByName']),
      paidToName: JsonUtils.parseString(json['paidToName']),
      amount: JsonUtils.parseDouble(json['amount']),
      settlementDate: JsonUtils.parseString(json['settlementDate']),
      settledAt: JsonUtils.parseString(json['settledAt']),
      message: JsonUtils.parseString(json['message']),
    );
  }
}