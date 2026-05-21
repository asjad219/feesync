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
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      accountId: json['account_id'],
      studentId: json['student_id'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'].toString().replaceAll('_', ''),
        orElse: () => PaymentMethod.other,
      ),
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      recordedBy: json['recorded_by'],
      notes: json['notes'],
      receiptNumber: json['receipt_number'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      student: json['students'] != null
          ? StudentInfo.fromJson(json['students'])
          : null,
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
    };
  }
}

class StudentInfo {
  final String firstName;
  final String lastName;
  final String studentClass;
  final String admissionNumber;

  StudentInfo({
    required this.firstName,
    required this.lastName,
    required this.studentClass,
    required this.admissionNumber,
  });

  String get fullName => '$firstName $lastName';

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentClass: json['class'],
      admissionNumber: json['admission_number'],
    );
  }
}
