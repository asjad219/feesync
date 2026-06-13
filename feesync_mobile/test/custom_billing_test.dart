import 'package:flutter_test/flutter_test.dart';
import 'package:feesync_mobile/models/student.dart';

void main() {
  group('Student Balance Custom Billing Tests', () {
    test('Correctly parses StudentBalance JSON with custom billing amounts', () {
      final json = {
        'id': 's1',
        'account_id': 'a1',
        'admission_number': '101',
        'roll_number': 'R-1',
        'first_name': 'Aarav',
        'last_name': 'Kumar',
        'class': 'Maths Batch',
        'batch_id': 'b1',
        'section': 'A',
        'parent_name': 'Rajesh Kumar',
        'parent_phone': '9876543210',
        'parent_email': 'rajesh@example.com',
        'gender': 'male',
        'total_fee_amount': 750.0,
        'total_paid_amount': 250.0,
        'balance': 500.0,
        'due_amount': 500.0,
        'status': 'DUE',
      };

      final studentBalance = StudentBalance.fromJson(json);

      expect(studentBalance.id, equals('s1'));
      expect(studentBalance.totalFeeAmount, equals(750.0));
      expect(studentBalance.totalPaidAmount, equals(250.0));
      expect(studentBalance.balance, equals(500.0));
      expect(studentBalance.dueAmount, equals(500.0));
      expect(studentBalance.status, equals('DUE'));
    });
  });
}
