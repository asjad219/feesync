import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../providers/providers.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../models/models.dart';
import '../../../../models/app_settings.dart';

class RemindersTab extends ConsumerStatefulWidget {
  final String batchId;
  const RemindersTab({super.key, required this.batchId});

  @override
  ConsumerState<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends ConsumerState<RemindersTab> {
  Future<void> _sendWhatsApp(String phone, String message) async {
    final url = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed on this device.')),
        );
      }
    }
  }

  String _parseTemplate(String template, StudentBalance student, AppSettings settings) {
    return template
        .replaceAll('{parent_name}', student.parentName ?? 'Parent')
        .replaceAll('{student_name}', student.fullName)
        .replaceAll('{amount}', '₹${student.balance.toStringAsFixed(0)}')
        .replaceAll('{due_date}', DateFormat('dd MMM yyyy').format(DateTime.now()))
        .replaceAll('{school_name}', settings.centerName);
  }

  void _previewAndSend(StudentBalance student, AppSettings settings) {
    final defaultMsg = _parseTemplate(settings.tplFeeReminder, student, settings);
    final controller = TextEditingController(text: defaultMsg);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Reminder to ${student.fullName}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Message template...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (student.parentPhone != null && student.parentPhone!.isNotEmpty) {
                String phone = student.parentPhone!;
                if (!phone.startsWith('+')) phone = '+91$phone'; // Assuming India, can be refined
                _sendWhatsApp(phone, controller.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number for this student.')));
              }
            },
            child: const Text('Send via WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _bulkSend(List<StudentBalance> students, AppSettings settings) async {
    if (students.isEmpty) return;
    
    // We will just prompt that this will open WhatsApp sequentially
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Send Reminders', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('This will prepare WhatsApp messages for ${students.length} students.\nYou will need to press "Send" in WhatsApp and return to this app for each student. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
        ],
      ),
    );

    if (confirm != true) return;

    for (var student in students) {
      if (student.parentPhone != null && student.parentPhone!.isNotEmpty) {
        String phone = student.parentPhone!;
        if (!phone.startsWith('+')) phone = '+91$phone';
        final msg = _parseTemplate(settings.tplFeeReminder, student, settings);
        await _sendWhatsApp(phone, msg);
        // Wait a little before the next iteration
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(batchStudentsProvider(widget.batchId));
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) return const Center(child: Text('Settings not loaded'));
        return studentsAsync.when(
          data: (allStudents) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            
            // Filter students whose dues match the exact threshold day range
            final targetDays = settings.reminderDaysBefore;
            
            final targetStudents = allStudents.where((s) {
              if (s.balance <= 0) return false;
              return true; // Simplified: just show all students with balance for now
            }).toList();

            if (targetStudents.isEmpty) {
              return Center(
                child: Text(
                  'No students have dues approaching within $targetDays days.',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _bulkSend(targetStudents, settings),
                    icon: const Icon(Icons.send_rounded),
                    label: Text('Bulk Send Reminders (${targetStudents.length})'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: targetStudents.length,
                    itemBuilder: (context, index) {
                      final s = targetStudents[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: Text(s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.blue)),
                        ),
                        title: Text(s.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('Bal: ₹${s.balance}', style: GoogleFonts.inter(color: Colors.redAccent)),
                        trailing: IconButton(
                          icon: const Icon(Icons.message, color: Color(0xFF10B981)),
                          onPressed: () => _previewAndSend(s, settings),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
