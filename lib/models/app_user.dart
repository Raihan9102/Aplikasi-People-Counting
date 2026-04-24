class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final int createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<dynamic, dynamic> map) {
    return AppUser(
      id: id,
      // Ubah '-' menjadi ''
      name: (map['name'] ?? '-').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      createdAt: _toInt(map['created_at']),
    );
  }

  factory AppUser.empty() {
    return const AppUser(
      id: '-',
      name: '-',
      email: '-',
      role: '-',
      createdAt: 0,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
