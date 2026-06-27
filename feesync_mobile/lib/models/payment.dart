import 'student.dart';

enum PaymentMethod { cash, bankTransfer, mobileMoney, card, other }
enum PaymentStatus { pending, completed, refunded, cancelled }

class Payment {
  final String id;
  final String accountId;
  final String studentId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final DateTime paymentDate;
  final String? recordedBy;
  final String? notes;
  final String? receiptNumber;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudentInfo? student;
  final bool isOffline;
  
  final double? baseAmount;
  final double? lateFineAmount;
  final double? discountAmount;
  final double? taxAmount;

  Payment({
    required this.id,
    required this.accountId,
    required this.studentId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.paymentDate,
    this.recordedBy,
    this.notes,
    this.receiptNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.isOffline = false,
    this.baseAmount,
    this.lateFineAmount,
    this.discountAmount,
    this.taxAmount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      accountId: json['account_id'],
      studentId: json['student_id'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == json['payment_method'].toString().replaceAll('_', '').toLowerCase(),
        orElse: () => PaymentMethod.other,
      ),
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      recordedBy: json['recorded_by'],
      notes: json['notes'],
      receiptNumber: json['receipt_number'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      student: json['students'] != null
          ? StudentInfo.fromJson(json['students'])
          : null,
      isOffline: json['is_offline'] ?? false,
      baseAmount: json['base_amount'] != null ? double.parse(json['base_amount'].toString()) : null,
      lateFineAmount: json['late_fine_amount'] != null ? double.parse(json['late_fine_amount'].toString()) : null,
      discountAmount: json['discount_amount'] != null ? double.parse(json['discount_amount'].toString()) : null,
      taxAmount: json['tax_amount'] != null ? double.parse(json['tax_amount'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'student_id': studentId,
      'amount': amount,
      'payment_method': paymentMethod.name,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String(),
      'recorded_by': recordedBy,
      'notes': notes,
      'receipt_number': receiptNumber,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_offline': isOffline,
      'base_amount': baseAmount,
      'late_fine_amount': lateFineAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
    };
  }
}

class StudentInfo {
  final String firstName;
  final String lastName;
  final String studentClass;
  final String admissionNumber;
  final Gender? gender;

  StudentInfo({
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    required this.admissionNumber,
    this.gender,
  });

  String get fullName => '$firstName $lastName';

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentClass: json['class'],
      admissionNumber: json['admission_number'],
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == json['gender'].toString().toLowerCase(),
              orElse: () => Gender.other,
            )
          : null,
    );
  }
}
