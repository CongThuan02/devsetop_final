/// Plaintext (chỉ tồn tại trong RAM client sau khi giải mã).
class VaultItem {
  VaultItem({
    required this.id,
    required this.serviceName,
    required this.url,
    required this.username,
    required this.password,
    this.note = '',
  });

  final String id;
  final String serviceName;
  final String url;
  final String username;
  final String password;
  final String note;
}

/// Phần plaintext sẽ được mã hoá thành 1 chuỗi JSON duy nhất.
class VaultItemSecret {
  VaultItemSecret({
    required this.username,
    required this.password,
    this.note = '',
  });

  final String username;
  final String password;
  final String note;

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'note': note,
  };

  factory VaultItemSecret.fromJson(Map<String, dynamic> j) => VaultItemSecret(
    username: j['username'] as String? ?? '',
    password: j['password'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );
}
