// Accept Invite Screen — shown when a user taps an invite link / views their pending invites.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/family_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/family_api_service.dart';
import '../../../utils/responsive_utils.dart';

class AcceptInviteScreen extends ConsumerStatefulWidget {
  /// Pre-loaded invite (when navigating from My Invites list).
  final MyInviteDto? invite;

  /// Direct token (e.g. deep link).
  final String? token;

  const AcceptInviteScreen({super.key, this.invite, this.token});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  bool _isLoading = false;
  bool _isDeclining = false;
  InvitePreviewDto? _preview;
  bool _isLoadingPreview = false;
  String? _previewError;

  MyInviteDto? get _invite => widget.invite;
  String get _token => widget.invite?.token ?? widget.token ?? '';

  @override
  void initState() {
    super.initState();
    // If we only have a token (deep link) and no pre-loaded invite data,
    // fetch the invite preview from the backend so the user sees details.
    if (widget.invite == null &&
        widget.token != null &&
        widget.token!.isNotEmpty) {
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });
    try {
      final preview = await FamilyApiService.instance.validateInvite(_token);
      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _previewError = e.toString();
          _isLoadingPreview = false;
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    if (_token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FamilyApiService.instance.acceptInvite(_token);
      // Invalidate all home/asset providers so the new home and its
      // granted assets appear immediately without a cold restart.
      ref.invalidate(homeSelectionProvider);
      ref.invalidate(homesProvider);
      ref.invalidate(assetsProvider);
      // Remove this invite from the pending-invites banner on the home screen.
      ref.invalidate(myPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite accepted! You now have access.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/my-family-access');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineInvite() async {
    if (_token.isEmpty) return;
    setState(() => _isDeclining = true);
    try {
      await FamilyApiService.instance.declineInvite(_token);
      ref.invalidate(myPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invite declined.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _isDeclining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: responsive.iconSize(24.0),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Family Invite',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.spacing(24.0)),
          child: _invite != null
              ? _buildInviteDetails(responsive)
              : _buildTokenOnlyView(responsive),
        ),
      ),
    );
  }

  Widget _buildInviteDetails(ResponsiveUtils responsive) {
    final invite = _invite!;
    final homeName = invite.home != null
        ? '${invite.home!.address}, ${invite.home!.city}'
        : 'A home';
    final inviterName =
        invite.invitedBy?.name ?? invite.invitedBy?.email ?? 'Someone';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: responsive.spacing(24.0)),
        // Icon
        Container(
          width: responsive.spacing(80.0),
          height: responsive.spacing(80.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.home, size: responsive.iconSize(40.0), color: _primaryColor),
        ),
        SizedBox(height: responsive.spacing(24.0)),
        Text(
          'You\'ve been invited!',
          style: TextStyle(
            fontSize: responsive.fontSize(22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(12.0)),
        Text(
          '$inviterName has invited you to access',
          style: TextStyle(
            fontSize: responsive.fontSize(15.0),
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(4.0)),
        Text(
          homeName,
          style: TextStyle(
            fontSize: responsive.fontSize(16.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(24.0)),
        // Details card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(16.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoRow('Role', _capitalizeRole(invite.role), responsive),
              if (invite.relation != null && invite.relation!.isNotEmpty) ...[
                Divider(color: AppColors.gray300, height: 20),
                _infoRow('Relation', invite.relation!, responsive),
              ],
              if (invite.isExpired) ...[
                Divider(color: AppColors.gray300, height: 20),
                const Row(
                  children: [
                    Icon(Icons.warning_amber, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'This invite has expired',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(32.0)),
        // Action buttons
        if (!invite.isExpired) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _acceptInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Accept Invite',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: responsive.spacing(12.0)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_isLoading || _isDeclining) ? null : _declineInvite,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.gray300),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeclining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
        SizedBox(height: responsive.spacing(16.0)),
      ],
    );
  }

  Widget _buildTokenOnlyView(ResponsiveUtils responsive) {
    final isAuthenticated = ref.watch(authProvider) == AuthState.authenticated;

    // If authenticated and we have a preview loaded, show full details
    if (isAuthenticated && _preview != null) {
      return _buildPreviewDetails(responsive);
    }

    // Loading state for preview
    if (isAuthenticated && _isLoadingPreview) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: responsive.spacing(48.0)),
        Container(
          width: responsive.spacing(80.0),
          height: responsive.spacing(80.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor.withValues(alpha: 0.1),
          ),
          child: Icon(
            isAuthenticated ? Icons.mail : Icons.lock_outline,
            size: responsive.iconSize(40.0),
            color: _primaryColor,
          ),
        ),
        SizedBox(height: responsive.spacing(24.0)),
        Text(
          isAuthenticated ? 'Accept Family Invite?' : 'Sign in to Accept',
          style: TextStyle(
            fontSize: responsive.fontSize(22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(12.0)),
        Text(
          isAuthenticated
              ? (_previewError != null
                    ? 'Could not load invite details. You can still try to accept.'
                    : 'Tap below to accept the family access invite.')
              : 'You need to sign in or create an account before you can accept this invite.',
          style: TextStyle(
            fontSize: responsive.fontSize(15.0),
            color: _previewError != null
                ? AppColors.error
                : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(32.0)),
        if (isAuthenticated) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _acceptInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Accept Invite',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: responsive.spacing(12.0)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_isLoading || _isDeclining) ? null : _declineInvite,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.gray300),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeclining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/signin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(12.0)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/signup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: responsive.spacing(16.0)),
      ],
    );
  }

  Widget _buildPreviewDetails(ResponsiveUtils responsive) {
    final preview = _preview!;
    final homeName = preview.home != null
        ? '${preview.home!.address}, ${preview.home!.city}'
        : 'A home';
    final inviterName =
        preview.invitedBy?.name ?? preview.invitedBy?.email ?? 'Someone';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: responsive.spacing(24.0)),
        Container(
          width: responsive.spacing(80.0),
          height: responsive.spacing(80.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.home, size: responsive.iconSize(40.0), color: _primaryColor),
        ),
        SizedBox(height: responsive.spacing(24.0)),
        Text(
          preview.isExpired
              ? 'Invite Expired'
              : preview.isAccepted
              ? 'Already Accepted'
              : !preview.emailMatch
              ? 'Wrong Account'
              : 'You\'ve been invited!',
          style: TextStyle(
            fontSize: responsive.fontSize(22.0),
            fontWeight: FontWeight.bold,
            color:
                (preview.isExpired || preview.isAccepted || !preview.emailMatch)
                ? AppColors.error
                : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(12.0)),
        if (!preview.emailMatch)
          Text(
            'This invite was sent to a different email. Please sign in with the correct account.',
            style: TextStyle(
              fontSize: responsive.fontSize(15.0),
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          )
        else ...[
          Text(
            '$inviterName has invited you to access',
            style: TextStyle(
              fontSize: responsive.fontSize(15.0),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            homeName,
            style: TextStyle(
              fontSize: responsive.fontSize(16.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: responsive.spacing(24.0)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(16.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoRow('Role', _capitalizeRole(preview.role), responsive),
              if (preview.relation != null && preview.relation!.isNotEmpty) ...[
                Divider(color: AppColors.gray300, height: 20),
                _infoRow('Relation', preview.relation!, responsive),
              ],
              if (preview.isExpired || preview.isAccepted) ...[
                Divider(color: AppColors.gray300, height: 20),
                Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview.isExpired
                            ? 'This invite has expired'
                            : 'This invite has already been accepted',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(32.0)),
        if (preview.isPending && preview.emailMatch) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _acceptInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Accept Invite',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: responsive.spacing(12.0)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_isLoading || _isDeclining) ? null : _declineInvite,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.gray300),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16.0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeclining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
        SizedBox(height: responsive.spacing(16.0)),
      ],
    );
  }

  Widget _infoRow(String label, String value, ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _capitalizeRole(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'member':
        return 'Member';
      case 'viewer':
        return 'Viewer';
      default:
        return role[0].toUpperCase() + role.substring(1);
    }
  }
}
