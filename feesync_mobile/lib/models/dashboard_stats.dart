class DashboardStats {
  final int totalStudents;
  final double totalFeesCollected;
  final double pendingFees;
  final double collectionRate;
  final DateTime lastUpdated;

  DashboardStats({
    required this.totalStudents,
    required this.totalFeesCollected,
    required this.pendingFees,
    required this.collectionRate,
    required this.lastUpdated,
  });
}

class MonthlyStat {
  final String month;
  final double amount;

  MonthlyStat({
    required this.month,
    required this.amount,
  });
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
}
