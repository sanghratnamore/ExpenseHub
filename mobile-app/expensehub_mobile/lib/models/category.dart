class Category {
  final int id;
  final String name;
  final String? type;


  Category({
    required this.id,
    required this.name,
    this.type,
  });


  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed',
      type: json['type'] ?? json['categoryType'],
    );
  }
}