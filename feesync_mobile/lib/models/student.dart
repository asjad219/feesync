enum Gender { male, female, other }

class Student {
  final String id;
  final String accountId;
  final String admissionNumber;
  final String firstName;
  final String lastName;
  final String studentClass;
  final String? section;
  final String? stream;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.accountId,
    required this.admissionNumber,
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    this.section,
    this.stream,
    this.gender,
    this.dateOfBirth,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      accountId: json['account_id'],
      admissionNumber: json['admission_number'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentClass: json['class'],
      section: json['section'],
      stream: json['stream'],
      gender: json['gender'] != null ? Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.other,
      ) : null,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'],
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'admission_number': admissionNumber,
      'first_name': firstName,
      'last_name': lastName,
      'class': studentClass,
      'section': section,
      'stream': stream,
      'gender': gender?.name,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StudentBalance {
  final String id;
  final String accountId;
  final String admissionNumber;
  final String firstName;
  final String lastName;
  final String studentClass;
  final String? section;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final double totalFeeAmount;
  final double totalPaidAmount;
  final double balance;

  StudentBalance({
    required this.id,
    required this.accountId,
    required this.admissionNumber,
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    this.section,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    required this.totalFeeAmount,
    required this.totalPaidAmount,
    required this.balance,
  });

  String get fullName => '$firstName $lastName';

  factory StudentBalance.fromJson(Map<String, dynamic> json) {
    return StudentBalance(
      id: json['id'],
      accountId: json['account_id'],
      admissionNumber: json['admission_number'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentClass: json['class'],
      section: json['section'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'],
      totalFeeAmount: double.parse(json['total_fee_amount'].toString()),
      totalPaidAmount: double.parse(json['total_paid_amount'].toString()),
      balance: double.parse(json['balance'].toString()),
    );
  }
}
