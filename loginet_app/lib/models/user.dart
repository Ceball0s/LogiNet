class User {
  final int id;
  final String email;
  final String role;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
