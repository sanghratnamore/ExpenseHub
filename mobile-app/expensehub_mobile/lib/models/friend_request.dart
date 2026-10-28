import '../utils/json_utils.dart';

class FriendRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String receiverId;
  final String receiverName;
  final String receiverEmail;
  final String status;

  FriendRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: JsonUtils.parseId(json['id']),
      requesterId: JsonUtils.parseId(json['requesterId']),
      requesterName: JsonUtils.parseString(json['requesterName']),
      requesterEmail: JsonUtils.parseString(json['requesterEmail']),
      receiverId: JsonUtils.parseId(json['receiverId']),
      receiverName: JsonUtils.parseString(json['receiverName']),
      receiverEmail: JsonUtils.parseString(json['receiverEmail']),
      status: JsonUtils.parseString(
        json['status'],
        fallback: 'PENDING',
      ),
    );
  }
}