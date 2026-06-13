import 'package:flutter_test/flutter_test.dart';
import 'package:feesync_mobile/models/student.dart';
import 'package:feesync_mobile/screens/batches/batch_detail_screen.dart';

void main() {
  group('Reminder Message Generation Tests', () {
    test('Standard replacement with all placeholders', () {
      final student = StudentBalance(
        id: 's1',
        accountId: 'a1',
        admissionNumber: '101',
        firstName: 'Aarav',
        lastName: 'Kumar',
        studentClass: 'Class 5',
        parentName: 'Rajesh Kumar',
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 3000,
        balance: 2000,
        dueAmount: 2000,
        status: 'DUE',
      );

      final msg = generateReminderMessage(
        template: 'Dear {parent_name}, fee of {due_amount} is due for {student_name} in {batch_name} on {due_date} at {institute_name}.',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Dear Rajesh Kumar, fee of ₹2,000 is due for Aarav Kumar in Morning Batch on 15 Jun 2026 at FeeSync Academy.'));
    });

    test('Fallback: Missing parent name', () {
      final student = StudentBalance(
        id: 's2',
        accountId: 'a1',
        admissionNumber: '102',
        firstName: 'Aarav',
        lastName: 'Kumar',
        studentClass: 'Class 5',
        parentName: null, // missing parent name
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 3000,
        balance: 2000,
        dueAmount: 2000,
        status: 'DUE',
      );

      final msg = generateReminderMessage(
        template: 'Dear {parent_name}, please check.',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Dear Parent, please check.'));
    });

    test('Fallback: Missing due amount', () {
      final student = StudentBalance(
        id: 's3',
        accountId: 'a1',
        admissionNumber: '103',
        firstName: 'Aarav',
        lastName: 'Kumar',
        studentClass: 'Class 5',
        parentName: 'Rajesh Kumar',
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 5000,
        balance: 0, // missing/no due amount
        dueAmount: 0,
        status: 'PAID',
      );

      final msg = generateReminderMessage(
        template: 'Fee of {due_amount} for {student_name}.',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Fee of Pending Fee for Aarav Kumar.'));
    });

    test('Fallback: Missing student name', () {
      final student = StudentBalance(
        id: 's4',
        accountId: 'a1',
        admissionNumber: '104',
        firstName: '', // missing student name
        lastName: '',
        studentClass: 'Class 5',
        parentName: 'Rajesh Kumar',
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 3000,
        balance: 2000,
        dueAmount: 2000,
        status: 'DUE',
      );

      final msg = generateReminderMessage(
        template: 'Reminder for {student_name}.',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Reminder for Student.'));
    });

    test('Sanitization: Clean unresolved placeholders', () {
      final student = StudentBalance(
        id: 's5',
        accountId: 'a1',
        admissionNumber: '105',
        firstName: 'Aarav',
        lastName: 'Kumar',
        studentClass: 'Class 5',
        parentName: 'Rajesh Kumar',
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 3000,
        balance: 2000,
        dueAmount: 2000,
        status: 'DUE',
      );

      final msg = generateReminderMessage(
        template: 'Hello {parent_name}, fee of {due_amount} is due for {student_name}. {some_unresolved_placeholder}',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Hello Rajesh Kumar, fee of ₹2,000 is due for Aarav Kumar. '));
    });

    test('Support settings-style school_name and amount placeholders', () {
      final student = StudentBalance(
        id: 's6',
        accountId: 'a1',
        admissionNumber: '106',
        firstName: 'Aarav',
        lastName: 'Kumar',
        studentClass: 'Class 5',
        parentName: 'Rajesh Kumar',
        parentPhone: '9876543210',
        totalFeeAmount: 5000,
        totalPaidAmount: 3000,
        balance: 2000,
        dueAmount: 2000,
        status: 'DUE',
      );

      final msg = generateReminderMessage(
        template: 'Dear {parent_name}, fee of {amount} is due. school: {school_name}',
        student: student,
        batchName: 'Morning Batch',
        instituteName: 'FeeSync Academy',
        dueDate: '15 Jun 2026',
      );

      expect(msg, equals('Dear Rajesh Kumar, fee of ₹2,000 is due. school: FeeSync Academy'));
    });
  });
}
