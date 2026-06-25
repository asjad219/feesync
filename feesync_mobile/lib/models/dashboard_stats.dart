import 'student.dart';

class DashboardStats {
  final int totalStudents;
  final double totalFeesCollected;
  final double pendingFees;
  final double collectionRate;
  final double growthPercentage;
  final bool isNewGrowth;
  final DateTime lastUpdated;

  DashboardStats({
    required this.totalStudents,
    required this.totalFeesCollected,
    required this.pendingFees,
    required this.collectionRate,
    required this.growthPercentage,
    required this.isNewGrowth,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json['totalStudents'] as int,
      totalFeesCollected: double.parse((json['totalFeesCollected'] ?? 0).toString()),
      pendingFees: double.parse((json['pendingFees'] ?? 0).toString()),
      collectionRate: double.parse((json['collectionRate'] ?? 0).toString()),
      growthPercentage: double.parse((json['growthPercentage'] ?? 0).toString()),
      isNewGrowth: json['isNewGrowth'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'totalFeesCollected': totalFeesCollected,
      'pendingFees': pendingFees,
      'collectionRate': collectionRate,
      'growthPercentage': growthPercentage,
      'isNewGrowth': isNewGrowth,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class MonthlyStat {
  final String month;
  final double amount;

  MonthlyStat({
    required this.month,
    required this.amount,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: json['month'] as String,
      amount: double.parse((json['amount'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
    };
  }
}

class CategoryStat {
  final String name;
  final double amount;
  final double percentage;

  CategoryStat({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

class ClassStat {
  final String className;
  final double collected;
  final double pending;

  ClassStat({
    required this.className,
    required this.collected,
    required this.pending,
  });

  factory ClassStat.fromJson(Map<String, dynamic> json) {
    return ClassStat(
      className: json['className'] as String,
      collected: double.parse((json['collected'] ?? 0).toString()),
      pending: double.parse((json['pending'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'collected': collected,
      'pending': pending,
    };
  }
}

class RecentTransaction {
  final String id;
  final String studentName;
  final String studentClass;
  final double amount;
  final String feeType;
  final DateTime date;
  final String paymentMethod;
  final Gender? studentGender;

  RecentTransaction({
    required this.id,
    required this.studentName,
    required this.studentClass,
    required this.amount,
    required this.feeType,
    required this.date,
    required this.paymentMethod,
    this.studentGender,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      studentClass: json['studentClass'] as String,
      amount: double.parse((json['amount'] ?? 0).toString()),
      feeType: json['feeType'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String,
      studentGender: json['studentGender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == json['studentGender'].toString().toLowerCase(),
              orElse: () => Gender.other,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'studentClass': studentClass,
      'amount': amount,
      'feeType': feeType,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'studentGender': studentGender?.name,
    };
  }
}
