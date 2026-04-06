import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';

/// Modern form for adding a family member
class AddFamilyMemberForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onMemberAdded;

  const AddFamilyMemberForm({super.key, this.onMemberAdded});

  @override
  State<AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<AddFamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'Member';
  bool _isLoading = false;

  final List<String> _roles = ['Admin', 'Member'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Family Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: AppDimensions.spacing24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Information',
                      style: TextStyle(
                        fontSize: AppDimensions.fontL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter member name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: AppValidators.name,
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'member@example.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1 234 567 8900',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Level',
                      style: TextStyle(
                        fontSize: AppDimensions.fontL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    ..._roles.map((role) => _buildRoleOption(role)),
                    const SizedBox(height: AppDimensions.spacing16),
                    _buildRoleExplanation(),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Send Invitation',
                  onPressed: _isLoading ? null : _handleSubmit,
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Text(
              'An invitation email will be sent to the member',
              style: TextStyle(
                fontSize: AppDimensions.fontS,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role) {
    final isSelected = _selectedRole == role;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: AppDimensions.fontM,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    role == 'Admin'
                        ? 'Can manage all home features'
                        : 'Can view and book services',
                    style: TextStyle(
                      fontSize: AppDimensions.fontS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleExplanation() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPermissionItem('Admin', 'Full access to all features', true),
          _buildPermissionItem('Member', 'View assets and book services', true),
          _buildPermissionItem('Member', 'Cannot delete or add members', false),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String role, String description, bool allowed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: allowed ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: AppDimensions.fontXs,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Submit to API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      final member = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': _selectedRole,
      };

      widget.onMemberAdded?.call(member);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Invitation sent successfully');
        Navigator.of(context).pop();
      }
    } on Object catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to send invitation');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
