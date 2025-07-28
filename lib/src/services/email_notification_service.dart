import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../models/reimbursement_request.dart';

class EmailNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Singleton pattern
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  // Configuration for email service
  static const String _approvalBaseUrl = 'https://your-app-domain.com/approve';

  /// Send notification to Financial Secretary/Comptroller
  Future<void> sendNotificationToFinancialOfficer(ReimbursementRequest request) async {
    try {
      final subject = '[Council ${request.organizationId}] New Reimbursement Request - ${request.voucherNumber}';
      final body = _generateFinancialOfficerEmailBody(request);
      
      await _sendEmail(
        to: await _getFinancialOfficerEmail(request.organizationId),
        subject: subject,
        body: body,
        requestId: request.id,
      );
      
      AppLogger.info('Email notification sent to Financial Officer for request ${request.id}');
    } catch (e) {
      AppLogger.error('Failed to send email to Financial Officer', e);
      // Don't throw - email failure shouldn't break the workflow
    }
  }

  /// Send notification to Grand Knight/Faithful Navigator
  Future<void> sendNotificationToGrandKnight(ReimbursementRequest request) async {
    try {
      final subject = '[Council ${request.organizationId}] Reimbursement Voucher Approval Required - ${request.voucherNumber}';
      final approvalToken = await _generateApprovalToken(request.id, 'grand_knight');
      final approvalUrl = '$_approvalBaseUrl?token=$approvalToken&action=approve';
      final rejectionUrl = '$_approvalBaseUrl?token=$approvalToken&action=reject';
      
      final body = _generateGrandKnightEmailBody(request, approvalUrl, rejectionUrl);
      
      await _sendEmail(
        to: await _getGrandKnightEmail(request.organizationId),
        subject: subject,
        body: body,
        requestId: request.id,
      );
      
      AppLogger.info('Email notification sent to Grand Knight for voucher ${request.voucherNumber}');
    } catch (e) {
      AppLogger.error('Failed to send email to Grand Knight', e);
    }
  }

  /// Send notification to Treasurer/Purser
  Future<void> sendNotificationToTreasurer(ReimbursementRequest request) async {
    try {
      final subject = '[Council ${request.organizationId}] Payment Required - ${request.voucherNumber}';
      final paymentToken = await _generateApprovalToken(request.id, 'treasurer');
      final paymentUrl = '$_approvalBaseUrl?token=$paymentToken&action=pay';
      
      final body = _generateTreasurerEmailBody(request, paymentUrl);
      
      await _sendEmail(
        to: await _getTreasurerEmail(request.organizationId),
        subject: subject,
        body: body,
        requestId: request.id,
      );
      
      AppLogger.info('Email notification sent to Treasurer for voucher ${request.voucherNumber}');
    } catch (e) {
      AppLogger.error('Failed to send email to Treasurer', e);
    }
  }

  /// Send denial email to requester
  Future<void> sendDenialEmail(ReimbursementRequest request, String reason) async {
    try {
      final subject = '[Council ${request.organizationId}] Reimbursement Request Denied - ${request.voucherNumber}';
      final body = _generateDenialEmailBody(request, reason);
      
      await _sendEmail(
        to: request.requesterEmail,
        subject: subject,
        body: body,
        requestId: request.id,
      );
      
      AppLogger.info('Denial email sent to ${request.requesterEmail} for request ${request.id}');
    } catch (e) {
      AppLogger.error('Failed to send denial email', e);
    }
  }

  /// Send email using Supabase Edge Function or external service
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String body,
    required String requestId,
  }) async {
    try {
      // Try Supabase Edge Function first
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'body': body,
          'requestId': requestId,
        },
      );
      
      if (response.status != 200) {
        throw Exception('Email service returned status ${response.status}');
      }
      
      // Log email notification
      await _logEmailNotification(requestId, to, 'sent');
      
    } catch (e) {
      AppLogger.error('Supabase email function failed, trying fallback', e);
      
      // Fallback to external email service (if configured)
      await _sendEmailFallback(to, subject, body, requestId);
    }
  }

  /// Fallback email service using external provider
  Future<void> _sendEmailFallback(String to, String subject, String body, String requestId) async {
    // This would integrate with SendGrid, AWS SES, or other email service
    // For now, we'll just log it as the email service isn't fully configured
    AppLogger.info('Fallback email service would send: $subject to $to');
    await _logEmailNotification(requestId, to, 'fallback_logged');
  }

  /// Generate approval token for secure email links
  Future<String> _generateApprovalToken(String requestId, String role) async {
    final token = '${requestId}_${role}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Store token in database with expiration
    await _supabase.from('email_approval_tokens').insert({
      'id': token,
      'request_id': requestId,
      'role': role,
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    return token;
  }

  /// Get Financial Officer email from organization settings
  Future<String> _getFinancialOfficerEmail(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('financial_officer_email')
          .eq('id', organizationId)
          .single();
      
      return response['financial_officer_email'] ?? 'financial@council$organizationId.com';
    } catch (e) {
      AppLogger.warning('Could not get Financial Officer email, using default');
      return 'financial@council$organizationId.com';
    }
  }

  /// Get Grand Knight email from organization settings
  Future<String> _getGrandKnightEmail(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('grand_knight_email')
          .eq('id', organizationId)
          .single();
      
      return response['grand_knight_email'] ?? 'gk@council$organizationId.com';
    } catch (e) {
      AppLogger.warning('Could not get Grand Knight email, using default');
      return 'gk@council$organizationId.com';
    }
  }

  /// Get Treasurer email from organization settings
  Future<String> _getTreasurerEmail(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('treasurer_email')
          .eq('id', organizationId)
          .single();
      
      return response['treasurer_email'] ?? 'treasurer@council$organizationId.com';
    } catch (e) {
      AppLogger.warning('Could not get Treasurer email, using default');
      return 'treasurer@council$organizationId.com';
    }
  }

  /// Log email notification in database
  Future<void> _logEmailNotification(String requestId, String email, String status) async {
    try {
      await _supabase.from('email_notifications').insert({
        'id': '${requestId}_${DateTime.now().millisecondsSinceEpoch}',
        'request_id': requestId,
        'role_email': email,
        'notification_type': 'reimbursement_approval',
        'status': status,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Failed to log email notification', e);
    }
  }

  /// Generate email body for Financial Officer notification
  String _generateFinancialOfficerEmailBody(ReimbursementRequest request) {
    return '''
Dear Financial Secretary/Comptroller,

A new reimbursement request has been submitted and requires your review:

Voucher Number: ${request.voucherNumber}
Requester: ${request.requesterName}
Amount: \$${request.amount.toStringAsFixed(2)}
Description: ${request.description}
Program: ${request.programName}
Date Submitted: ${request.createdAt.toLocal().toString().split('.')[0]}

Please log into the KC Management System to review and approve this request.

Best regards,
KC Management System
''';
  }

  /// Generate email body for Grand Knight approval
  String _generateGrandKnightEmailBody(ReimbursementRequest request, String approvalUrl, String rejectionUrl) {
    return '''
Dear Grand Knight,

A reimbursement voucher requires your approval:

Voucher Number: ${request.voucherNumber}
Requester: ${request.requesterName}
Amount: \$${request.amount.toStringAsFixed(2)}
Description: ${request.description}
Program: ${request.programName}
Date Submitted: ${request.createdAt.toLocal().toString().split('.')[0]}

To approve this voucher: $approvalUrl
To reject this voucher: $rejectionUrl

This approval link expires in 7 days.

Best regards,
KC Management System
''';
  }

  /// Generate email body for Treasurer payment
  String _generateTreasurerEmailBody(ReimbursementRequest request, String paymentUrl) {
    return '''
Dear Treasurer,

A reimbursement voucher has been approved and requires payment:

Voucher Number: ${request.voucherNumber}
Requester: ${request.requesterName}
Amount: \$${request.amount.toStringAsFixed(2)}
Description: ${request.description}
Program: ${request.programName}
Approved by: ${request.approvedBy ?? 'Financial Officer'}

To mark as paid: $paymentUrl

This payment link expires in 7 days.

Best regards,
KC Management System
''';
  }

  /// Generate email body for denial notification
  String _generateDenialEmailBody(ReimbursementRequest request, String reason) {
    return '''
Dear ${request.requesterName},

Your reimbursement request has been denied:

Voucher Number: ${request.voucherNumber}
Amount: \$${request.amount.toStringAsFixed(2)}
Description: ${request.description}
Reason for Denial: $reason

If you have any questions, please contact your Financial Secretary or Grand Knight.

Best regards,
KC Management System
''';
  }
} 