class User {
  final int id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['Id'] ?? 0,
      email: json['email'] ?? json['Email'] ?? '',
      name: json['nombre'] ?? json['name'] ?? json['Nombre'] ?? '',
    );
  }
}
