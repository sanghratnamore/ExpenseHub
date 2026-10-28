import '../utils/json_utils.dart';

class SettlementSuggestion {
  final String? id;
  final String groupId;
  final String? paidById;
  final String paidByName;
  final String? paidToId;
  final String paidToName;
  final double amount;
  final String? settlementDate;
  final String? settledAt;
  final String message;

  SettlementSuggestion({
    this.id,
    required this.groupId,
    this.paidById,
    required this.paidByName,
    this.paidToId,
    required this.paidToName,
    required this.amount,
    this.settlementDate,
    this.settledAt,
    required this.message,
  });

  factory SettlementSuggestion.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementSuggestion(
      id: JsonUtils.parseOptionalId(json['id']),
      groupId: JsonUtils.parseId(json['groupId']),
      paidById: JsonUtils.parseOptionalId(json['paidById']),
      paidByName: JsonUtils.parseString(json['paidByName']),
      paidToId: JsonUtils.parseOptionalId(json['paidToId']),
      paidToName: JsonUtils.parseString(json['paidToName']),
      amount: JsonUtils.parseDouble(json['amount']),
      settlementDate: JsonUtils.parseOptionalString(
        json['settlementDate'],
      ),
      settledAt: JsonUtils.parseOptionalString(json['settledAt']),
      message: JsonUtils.parseString(json['message']),
    );
  }
}