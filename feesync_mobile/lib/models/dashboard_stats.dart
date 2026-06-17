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
      totalFeesCollected: (json['totalFeesCollected'] as num).toDouble(),
      pendingFees: (json['pendingFees'] as num).toDouble(),
      collectionRate: (json['collectionRate'] as num).toDouble(),
      growthPercentage: (json['growthPercentage'] as num).toDouble(),
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
      amount: (json['amount'] as num).toDouble(),
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
      collected: (json['collected'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
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

  RecentTransaction({
    required this.id,
    required this.studentName,
    required this.studentClass,
    required this.amount,
    required this.feeType,
    required this.date,
    required this.paymentMethod,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      studentClass: json['studentClass'] as String,
      amount: (json['amount'] as num).toDouble(),
      feeType: json['feeType'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String,
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
    };
  }
}
