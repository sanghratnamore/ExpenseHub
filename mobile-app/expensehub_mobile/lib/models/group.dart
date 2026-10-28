import '../utils/json_utils.dart';

class GroupMember {
  final String id;
  final String name;
  final String email;
  final String role;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'MEMBER',
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: JsonUtils.parseId(json['id']),
      name: JsonUtils.parseString(json['name']),
      email: JsonUtils.parseString(json['email']),
      role: JsonUtils.parseString(
        json['role'],
        fallback: 'MEMBER',
      ),
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final List<GroupMember> members;
  final String? inviteCode;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    this.inviteCode,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: JsonUtils.parseId(json['id']),
      name: JsonUtils.parseString(json['name']),
      description: JsonUtils.parseString(json['description']),
      inviteCode: JsonUtils.parseOptionalString(json['inviteCode']),
      members: (json['members'] as List<dynamic>? ?? [])
          .map(
            (member) => GroupMember.fromJson(
              member as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}