enum Gender { male, female, other }

class Student {
  final String id;
  final String accountId;
  final String admissionNumber;
  final String firstName;
  final String lastName;
  final String studentClass;
  final String? batchId;
  final String? section;
  final String? stream;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? address;
  final String? rollNumber;
  final DateTime? joiningDate;
  final double discountAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.accountId,
    required this.admissionNumber,
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    this.batchId,
    this.section,
    this.stream,
    this.gender,
    this.dateOfBirth,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.address,
    this.rollNumber,
    this.joiningDate,
    this.discountAmount = 0,
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
      batchId: json['batch_id'],
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
      rollNumber: json['roll_number'],
      joiningDate: json['joining_date'] != null
          ? DateTime.parse(json['joining_date'])
          : null,
      discountAmount: double.parse((json['discount_amount'] ?? 0).toString()),
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
      'batch_id': batchId,
      'section': section,
      'stream': stream,
      'gender': gender?.name,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'address': address,
      'roll_number': rollNumber,
      'joining_date': joiningDate?.toIso8601String().split('T')[0],
      'discount_amount': discountAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StudentBalance {
  final String id;
  final String accountId;
  final String admissionNumber;
  final String? rollNumber;
  final String firstName;
  final String lastName;
  final String studentClass;
  final String? batchId;
  final String? section;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final Gender? gender;
  final double totalFeeAmount;
  final double totalPaidAmount;
  final double balance;
  final double dueAmount;
  final String status;

  StudentBalance({
    required this.id,
    required this.accountId,
    required this.admissionNumber,
    this.rollNumber,
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    this.batchId,
    this.section,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.gender,
    required this.totalFeeAmount,
    required this.totalPaidAmount,
    required this.balance,
    required this.dueAmount,
    required this.status,
  });

  String get fullName => '$firstName $lastName';

  factory StudentBalance.fromJson(Map<String, dynamic> json) {
    return StudentBalance(
      id: json['id'],
      accountId: json['account_id'],
      admissionNumber: json['admission_number'],
      rollNumber: json['roll_number'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentClass: json['class'],
      batchId: json['batch_id'],
      section: json['section'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'],
      gender: json['gender'] != null ? Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.other,
      ) : null,
      totalFeeAmount: double.parse(json['total_fee_amount'].toString()),
      totalPaidAmount: double.parse(json['total_paid_amount'].toString()),
      balance: double.parse(json['balance'].toString()),
      dueAmount: double.parse((json['due_amount'] ?? 0).toString()),
      status: json['status'] ?? 'DUE',
    );
  }
}
