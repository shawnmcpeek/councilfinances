class ReimbursementRequest {
  final String id;
  final String organizationId;
  final String organizationType; // 'council' or 'assembly'
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String requesterPhone;
  final String programId;
  final String programName;
  final String description;
  final double amount;
  final String recipientType; // 'self' or 'donation'
  final String? donationEntity; // For donation type
  final String deliveryMethod; // 'meeting', 'mail', or 'online'
  final String? mailingAddress;
  final String status; // 'pending', 'approved', 'denied', 'voucher_created', 'gk_approved', 'paid'
  final String? denialReason;
  final String? voucherNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? deniedBy;
  final DateTime? deniedAt;
  final String? voucherCreatedBy;
  final DateTime? voucherCreatedAt;
  final String? gkApprovedBy;
  final DateTime? gkApprovedAt;
  final String? paidBy;
  final DateTime? paidAt;
  final List<String> documentUrls; // URLs to uploaded documents

  ReimbursementRequest({
    required this.id,
    required this.organizationId,
    required this.organizationType,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.requesterPhone,
    required this.programId,
    required this.programName,
    required this.description,
    required this.amount,
    required this.recipientType,
    this.donationEntity,
    required this.deliveryMethod,
    this.mailingAddress,
    required this.status,
    this.denialReason,
    this.voucherNumber,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvedAt,
    this.deniedBy,
    this.deniedAt,
    this.voucherCreatedBy,
    this.voucherCreatedAt,
    this.gkApprovedBy,
    this.gkApprovedAt,
    this.paidBy,
    this.paidAt,
    required this.documentUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'organization_type': organizationType,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'requester_phone': requesterPhone,
      'program_id': programId,
      'program_name': programName,
      'description': description,
      'amount': amount,
      'recipient_type': recipientType,
      'donation_entity': donationEntity,
      'delivery_method': deliveryMethod,
      'mailing_address': mailingAddress,
      'status': status,
      'denial_reason': denialReason,
      'voucher_number': voucherNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'denied_by': deniedBy,
      'denied_at': deniedAt?.toIso8601String(),
      'voucher_created_by': voucherCreatedBy,
      'voucher_created_at': voucherCreatedAt?.toIso8601String(),
      'gk_approved_by': gkApprovedBy,
      'gk_approved_at': gkApprovedAt?.toIso8601String(),
      'paid_by': paidBy,
      'paid_at': paidAt?.toIso8601String(),
      'document_urls': documentUrls,
    };
  }

  factory ReimbursementRequest.fromMap(Map<String, dynamic> map) {
    return ReimbursementRequest(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      organizationType: map['organization_type'] as String,
      requesterId: map['requester_id'] as String,
      requesterName: map['requester_name'] as String,
      requesterEmail: map['requester_email'] as String,
      requesterPhone: map['requester_phone'] as String,
      programId: map['program_id'] as String,
      programName: map['program_name'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      recipientType: map['recipient_type'] as String,
      donationEntity: map['donation_entity'] as String?,
      deliveryMethod: map['delivery_method'] as String,
      mailingAddress: map['mailing_address'] as String?,
      status: map['status'] as String,
      denialReason: map['denial_reason'] as String?,
      voucherNumber: map['voucher_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at'] as String) : null,
      deniedBy: map['denied_by'] as String?,
      deniedAt: map['denied_at'] != null ? DateTime.parse(map['denied_at'] as String) : null,
      voucherCreatedBy: map['voucher_created_by'] as String?,
      voucherCreatedAt: map['voucher_created_at'] != null ? DateTime.parse(map['voucher_created_at'] as String) : null,
      gkApprovedBy: map['gk_approved_by'] as String?,
      gkApprovedAt: map['gk_approved_at'] != null ? DateTime.parse(map['gk_approved_at'] as String) : null,
      paidBy: map['paid_by'] as String?,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      documentUrls: List<String>.from(map['document_urls'] as List),
    );
  }

  ReimbursementRequest copyWith({
    String? id,
    String? organizationId,
    String? organizationType,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? requesterPhone,
    String? programId,
    String? programName,
    String? description,
    double? amount,
    String? recipientType,
    String? donationEntity,
    String? deliveryMethod,
    String? mailingAddress,
    String? status,
    String? denialReason,
    String? voucherNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? deniedBy,
    DateTime? deniedAt,
    String? voucherCreatedBy,
    DateTime? voucherCreatedAt,
    String? gkApprovedBy,
    DateTime? gkApprovedAt,
    String? paidBy,
    DateTime? paidAt,
    List<String>? documentUrls,
  }) {
    return ReimbursementRequest(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      organizationType: organizationType ?? this.organizationType,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      recipientType: recipientType ?? this.recipientType,
      donationEntity: donationEntity ?? this.donationEntity,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      mailingAddress: mailingAddress ?? this.mailingAddress,
      status: status ?? this.status,
      denialReason: denialReason ?? this.denialReason,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      deniedBy: deniedBy ?? this.deniedBy,
      deniedAt: deniedAt ?? this.deniedAt,
      voucherCreatedBy: voucherCreatedBy ?? this.voucherCreatedBy,
      voucherCreatedAt: voucherCreatedAt ?? this.voucherCreatedAt,
      gkApprovedBy: gkApprovedBy ?? this.gkApprovedBy,
      gkApprovedAt: gkApprovedAt ?? this.gkApprovedAt,
      paidBy: paidBy ?? this.paidBy,
      paidAt: paidAt ?? this.paidAt,
      documentUrls: documentUrls ?? this.documentUrls,
    );
  }
} 