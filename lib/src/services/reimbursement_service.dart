import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reimbursement_request.dart';
import 'email_notification_service.dart';

class ReimbursementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailNotificationService _emailService = EmailNotificationService();

  // Create a new reimbursement request
  Future<void> createReimbursementRequest(ReimbursementRequest request) async {
    try {
      await _supabase
          .from('reimbursement_requests')
          .insert(request.toMap());
      
      // Send notification to Financial Officer (Financial Secretary/Comptroller)
      await _emailService.sendNotificationToFinancialOfficer(request);
    } catch (e) {
      throw Exception('Failed to create reimbursement request: $e');
    }
  }

  // Get reimbursement requests for an organization
  Future<List<ReimbursementRequest>> getReimbursementRequests(String organizationId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => ReimbursementRequest.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reimbursement requests: $e');
    }
  }

  // Get reimbursement requests for a specific user
  Future<List<ReimbursementRequest>> getUserReimbursementRequests(String userId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => ReimbursementRequest.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reimbursement requests: $e');
    }
  }

  // Get a single reimbursement request
  Future<ReimbursementRequest?> getReimbursementRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('id', requestId)
          .single();

      return ReimbursementRequest.fromMap(response);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Failed to get reimbursement request: $e');
    }
  }

  // Approve a reimbursement request (Financial Secretary/Comptroller)
  Future<void> approveRequest(String requestId, String approverId) async {
    try {
      final now = DateTime.now();
      await _supabase
          .from('reimbursement_requests')
          .update({
            'status': 'approved',
            'approved_by': approverId,
            'approved_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', requestId);

      // Create voucher and send notification to Grand Knight/Faithful Navigator
      final request = await getReimbursementRequest(requestId);
      if (request != null) {
        await _createVoucher(request);
        await _emailService.sendNotificationToGrandKnight(request);
      }
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  // Deny a reimbursement request
  Future<void> denyRequest(String requestId, String denierId, String reason) async {
    try {
      final now = DateTime.now();
      await _supabase
          .from('reimbursement_requests')
          .update({
            'status': 'denied',
            'denied_by': denierId,
            'denied_at': now.toIso8601String(),
            'denial_reason': reason,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', requestId);

      // Send email notification to requester
      final request = await getReimbursementRequest(requestId);
      if (request != null) {
        await _emailService.sendDenialEmail(request, reason);
      }
    } catch (e) {
      throw Exception('Failed to deny request: $e');
    }
  }

  // Grand Knight/Faithful Navigator approves voucher
  Future<void> approveVoucher(String requestId, String gkId) async {
    try {
      final now = DateTime.now();
      await _supabase
          .from('reimbursement_requests')
          .update({
            'status': 'gk_approved',
            'gk_approved_by': gkId,
            'gk_approved_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', requestId);

      // Send notification to Treasurer/Purser
      final request = await getReimbursementRequest(requestId);
      if (request != null) {
        await _emailService.sendNotificationToTreasurer(request);
      }
    } catch (e) {
      throw Exception('Failed to approve voucher: $e');
    }
  }

  // Mark request as paid (Treasurer/Purser)
  Future<void> markAsPaid(
    String requestId, 
    String payerId, {
    String? paymentMethod,
    String? checkNumber,
  }) async {
    try {
      final now = DateTime.now();
      await _supabase
          .from('reimbursement_requests')
          .update({
            'status': 'paid',
            'paid_by': payerId,
            'paid_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'payment_method': paymentMethod,
            'check_number': checkNumber,
          })
          .eq('id', requestId);

      // Expense entry is created automatically by database trigger
      // No need to manually create it here
    } catch (e) {
      throw Exception('Failed to mark as paid: $e');
    }
  }

  // Generate unique voucher number
  String _generateVoucherNumber(String organizationId, int sequenceNumber) {
    final prefix = organizationId.startsWith('C') ? 'CE' : 'AE';
    return '$prefix${sequenceNumber.toString().padLeft(3, '0')}';
  }

  // Create voucher
  Future<void> _createVoucher(ReimbursementRequest request) async {
    try {
      // Get the next sequence number for this organization
      final response = await _supabase
          .from('reimbursement_requests')
          .select('voucher_number')
          .eq('organization_id', request.organizationId)
          .not('voucher_number', 'is', null);

      final existingVouchers = (response as List)
          .where((data) => data['voucher_number'] != null)
          .map((data) => data['voucher_number'] as String)
          .toList();

      int nextSequence = 1;
      if (existingVouchers.isNotEmpty) {
        final lastVoucher = existingVouchers.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
        final lastSequence = int.tryParse(lastVoucher.substring(2)) ?? 0;
        nextSequence = lastSequence + 1;
      }

      final voucherNumber = _generateVoucherNumber(request.organizationId, nextSequence);
      final now = DateTime.now();

      await _supabase
          .from('reimbursement_requests')
          .update({
            'status': 'voucher_created',
            'voucher_number': voucherNumber,
            'voucher_created_by': request.approvedBy,
            'voucher_created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', request.id);
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }





  // Get pending requests for approval (for Financial Officers)
  Future<List<ReimbursementRequest>> getPendingRequests(String organizationId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => ReimbursementRequest.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  // Get approved vouchers for Grand Knight approval
  Future<List<ReimbursementRequest>> getApprovedVouchers(String organizationId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'voucher_created')
          .order('voucher_created_at', ascending: false);

      return (response as List)
          .map((data) => ReimbursementRequest.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get approved vouchers: $e');
    }
  }

  // Get GK approved vouchers for Treasurer payment
  Future<List<ReimbursementRequest>> getGkApprovedVouchers(String organizationId) async {
    try {
      final response = await _supabase
          .from('reimbursement_requests')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'gk_approved')
          .order('gk_approved_at', ascending: false);

      return (response as List)
          .map((data) => ReimbursementRequest.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get GK approved vouchers: $e');
    }
  }
} 