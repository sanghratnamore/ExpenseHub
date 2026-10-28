import '../utils/json_utils.dart';

class Friend {
  final String id;
  final String name;
  final String email;

  Friend({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: JsonUtils.parseId(json['id']),
      name: JsonUtils.parseString(json['name']),
      email: JsonUtils.parseString(json['email']),
    );
  }
}