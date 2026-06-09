import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/error_dialog.dart';
import '../../../../models/user_profile.dart';
import '../../../../providers/staff_provider.dart';

class InviteEditStaffScreen extends ConsumerStatefulWidget {
  final UserProfile? existingStaff;

  const InviteEditStaffScreen({super.key, this.existingStaff});

  @override
  ConsumerState<InviteEditStaffScreen> createState() => _InviteEditStaffScreenState();
}

class _InviteEditStaffScreenState extends ConsumerState<InviteEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  String _selectedRole = 'accountant';
  bool _isActive = true;

  final Map<String, bool> _permissions = {
    'view_students': true,
    'manage_students': false,
    'view_payments': true,
    'manage_payments': false,
    'view_reports': false,
    'manage_settings': false,
  };

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.existingStaff?.email ?? '');
    _nameController = TextEditingController(text: widget.existingStaff?.fullName ?? '');
    
    if (widget.existingStaff != null) {
      _selectedRole = widget.existingStaff!.role;
      _isActive = widget.existingStaff!.isActive;
      widget.existingStaff!.permissions.forEach((key, value) {
        if (_permissions.containsKey(key)) {
          _permissions[key] = value == true;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(staffNotifierProvider.notifier);

    try {
      if (widget.existingStaff == null) {
        await notifier.inviteStaff(
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          role: _selectedRole,
          permissions: _permissions,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Staff invited successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
        }
      } else {
        await notifier.updateStaff(
          widget.existingStaff!.id,
          role: _selectedRole,
          permissions: _permissions,
          isActive: _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Staff updated successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Delete Staff?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to permanently delete this staff member? They will lose all access.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => context.pop(true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(staffNotifierProvider.notifier);
      try {
        await notifier.deleteStaff(widget.existingStaff!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Staff deleted'), backgroundColor: AppColors.success),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          showErrorDialog(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStaff != null;
    final isLoading = ref.watch(staffNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Staff' : 'Invite Staff',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Details', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                enabled: !isEditing, // Cannot change email later easily
                validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 24),
              Text('Role & Access', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: AppColors.surfaceContainer,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin (Full Access)')),
                  DropdownMenuItem(value: 'accountant', child: Text('Accountant (Custom Access)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              if (_selectedRole == 'accountant') ...[
                const SizedBox(height: 20),
                Text('Permissions', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: _permissions.keys.map((key) {
                      final title = key.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
                      return SwitchListTile(
                        title: Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                        value: _permissions[key] ?? false,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _permissions[key] = val);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (isEditing) ...[
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Text('Account Active', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  subtitle: Text('If disabled, the user cannot log in or access data.', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  value: _isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Save Changes' : 'Send Invite', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : () => _confirmDelete(context),
                    child: Text('Delete Staff', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
