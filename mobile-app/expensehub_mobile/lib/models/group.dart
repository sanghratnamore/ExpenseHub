class GroupMember {
  final int id;
  final String name;
  final String email;


  GroupMember({
    required this.id,
    required this.name,
    required this.email,
  });


  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}


class Group {
  final int id;
  final String name;
  final String description;
  final List<GroupMember> members;


  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
  });


  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      members: (json['members'] as List<dynamic>? ?? [])
          .map((member) => GroupMember.fromJson(member))
          .toList(),
    );
  }
}


