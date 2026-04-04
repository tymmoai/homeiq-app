// ignore_for_file: use_null_aware_elements
import 'dart:convert';

import '../models/family_models.dart';
import 'api_client.dart';

/// Service for Family Members operations against backend-client `/api/v1/family`.
class FamilyApiService {
  FamilyApiService._();
  static final FamilyApiService instance = FamilyApiService._();

  final _api = ApiClient();

  // ─── Owner endpoints ────────────────────────────────────────────────────────

  /// Fetch family members for the owner's homes.
  Future<List<FamilyMemberDto>> getFamilyMembers({String? homeId}) async {
    final response = await _api.get(
      '/family',
      queryParameters: homeId != null ? {'homeId': homeId} : null,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((m) => FamilyMemberDto.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Invite a new family member with full access selections.
  Future<void> inviteMember({
    required String email,
    required String homeId,
    required String role,
    String? relation,
    String? inviteeName,
    bool grantFutureAssets = false,
    List<String>? assetIds,
    List<String>? serviceTypes,
  }) async {
    await _api.post(
      '/family/invite',
      body: {
        'email': email,
        'homeId': homeId,
        'role': role,
        if (relation != null && relation.isNotEmpty) 'relation': relation,
        if (inviteeName != null && inviteeName.isNotEmpty)
          'inviteeName': inviteeName,
        'grantFutureAssets': grantFutureAssets,
        if (assetIds != null && assetIds.isNotEmpty) 'assetIds': assetIds,
        if (serviceTypes != null && serviceTypes.isNotEmpty)
          'serviceTypes': serviceTypes,
      },
    );
  }

  /// Fetch pending (unused, not expired) invites for the owner's homes.
  Future<List<FamilyInviteDto>> getPendingInvites({String? homeId}) async {
    final response = await _api.get(
      '/family/pending-invites',
      queryParameters: homeId != null ? {'homeId': homeId} : null,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((i) => FamilyInviteDto.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// Cancel a pending invite.
  Future<void> cancelInvite(String inviteId) async {
    await _api.delete('/family/invites/$inviteId');
  }

  /// Get full access details for a specific member.
  Future<FamilyMemberAccessDto> getMemberAccess(String memberId) async {
    final response = await _api.get('/family/$memberId/access');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return FamilyMemberAccessDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Update a member's role, relation, asset access, service access.
  Future<void> updateMemberAccess(
    String memberId, {
    String? role,
    String? relation,
    bool? grantFutureAssets,
    List<String>? assetIds,
    List<String>? serviceTypes,
  }) async {
    await _api.put(
      '/family/$memberId/access',
      body: {
        if (role != null) 'role': role,
        if (relation != null) 'relation': relation,
        if (grantFutureAssets != null) 'grantFutureAssets': grantFutureAssets,
        if (assetIds != null) 'assetIds': assetIds,
        if (serviceTypes != null) 'serviceTypes': serviceTypes,
      },
    );
  }

  /// Remove a family member (cascade deletes access records).
  Future<void> removeMember(String memberId) async {
    await _api.delete('/family/$memberId');
  }

  /// Quick role update (backward compatibility).
  Future<void> updateRole(String memberId, String role) async {
    await _api.put('/family/$memberId/role', body: {'role': role});
  }

  // ─── Member endpoints (for invited user) ────────────────────────────────────

  /// Accept an invite using the token.
  Future<void> acceptInvite(String token) async {
    await _api.post('/family/accept-invite', body: {'token': token});
  }

  /// Validate/preview an invite by token (without accepting).
  Future<InvitePreviewDto> validateInvite(String token) async {
    final response = await _api.get(
      '/family/validate-invite',
      queryParameters: {'token': token},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return InvitePreviewDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Decline an invite using the token.
  Future<void> declineInvite(String token) async {
    await _api.post('/family/decline-invite', body: {'token': token});
  }

  /// Owner resends an existing invite (new token + reset expiry).
  Future<void> resendInvite(String inviteId) async {
    await _api.post('/family/resend-invite', body: {'inviteId': inviteId});
  }

  /// Family member voluntarily leaves a home.
  Future<void> leaveHome(String memberId) async {
    await _api.delete('/family/leave/$memberId');
  }

  /// Get my own family memberships and access details.
  Future<List<MyMembershipDto>> getMyAccess() async {
    final response = await _api.get('/family/my-access');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((m) => MyMembershipDto.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Get my pending invites (invites sent to my email).
  Future<List<MyInviteDto>> getMyInvites() async {
    final response = await _api.get('/family/my-invites');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((i) => MyInviteDto.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}
