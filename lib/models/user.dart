class User {
  final int id;
  final String username;
  final String name;
  final String address;
  final String? phone;
  final DateTime createdAt;
  final bool isAdmin;
  final String? role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.address,
    this.phone,
    required this.createdAt,
    this.isAdmin = false,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(), // Allow null value
      createdAt: DateTime.parse(json['created_at'].toString()),
      isAdmin: json['is_admin'] == true,
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'address': address,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'is_admin': isAdmin,
      'role': role,
    };
  }
}
