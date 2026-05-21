class UserProfile {
  final String id;
  final String accountId;
  final String email;
  final String fullName;
  final String role;
  final String? phone;

  UserProfile({
    required this.id,
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
    );
  }
}
