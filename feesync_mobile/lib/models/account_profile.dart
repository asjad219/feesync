class AccountProfile {
  final String id;
  final String name;
  final String? schoolName;
  final String email;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final String? gstin;

  AccountProfile({
    required this.id,
    required this.name,
    this.schoolName,
    required this.email,
    this.phone,
    this.address,
    this.logoUrl,
    this.gstin,
  });

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolName: json['school_name'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      logoUrl: json['logo_url'] as String?,
      gstin: json['gstin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'school_name': schoolName,
      'email': email,
      'phone': phone,
      'address': address,
      'logo_url': logoUrl,
      'gstin': gstin,
    };
  }
}
