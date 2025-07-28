# Reimbursement Email-Based Approval Workflow

## Overview

This document outlines the proposed enhancement to allow unregistered users to participate in the reimbursement approval workflow through email-based interactions, while maintaining the existing in-app workflow for registered users.

## Current State

The reimbursement system currently requires all participants to be registered users of the application. This creates a barrier for organizations where some key personnel (Treasurers, Grand Knights, etc.) may not want to register for the app but still need to participate in the approval process.

## Proposed Enhancement

### 1. Email Field Addition to User Roles

**Database Changes:**
```sql
-- Add email storage for roles in users table
ALTER TABLE users ADD COLUMN role_emails JSONB DEFAULT '{}';

-- Example structure:
-- {
--   "council_roles": {
--     "Treasurer": "treasurer@council15857.com",
--     "Grand Knight": "gk@council15857.com"
--   },
--   "assembly_roles": {
--     "Faithful Purser": "purser@assembly94.com"
--   }
-- }
```

**UI Changes:**
- Add email input fields in the user profile/role management section
- Allow full access users to set email addresses for roles
- Validate email format and uniqueness within organization

### 2. Email-Based Approval Workflow

**Approval Process:**
1. **Request Submitted** → Financial Officer receives in-app notification
2. **Financial Officer Approval** → Grand Knight receives email notification
3. **Grand Knight Approval** → Treasurer receives email notification  
4. **Treasurer Payment** → Request marked as paid, expense entry created

**Email Notifications:**
- **Subject:** `[Council 15857] Reimbursement Voucher Approval Required - Voucher CE001`
- **Content:** Include request details, amount, description, secure approval link
- **Actions:** Approve/Reject buttons or reply with decision

### 3. Technical Implementation

**Email Service Integration:**
```dart
// Enhanced ReimbursementService
class ReimbursementService {
  // Send email notification for approval
  Future<void> sendApprovalEmail({
    required String roleEmail,
    required String roleName,
    required ReimbursementRequest request,
    required String approvalUrl,
  }) async {
    // Integration with email service (SendGrid, AWS SES, etc.)
  }
  
  // Handle email webhook responses
  Future<void> handleEmailApproval({
    required String token,
    required String decision,
    required String voucherNumber,
  }) async {
    // Validate token and update request status
  }
}
```

**Security Considerations:**
- **Secure Tokens:** Generate unique, time-limited tokens for each approval
- **Email Validation:** Verify sender email matches role email
- **Audit Trail:** Log all email-based approvals with timestamps
- **Rate Limiting:** Prevent spam/abuse of approval links

### 4. Database Schema Updates

**New Tables:**
```sql
-- Store email approval tokens
CREATE TABLE email_approval_tokens (
    id TEXT PRIMARY KEY,
    request_id TEXT REFERENCES reimbursement_requests(id),
    role_email TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    decision TEXT CHECK (decision IN ('approve', 'reject'))
);

-- Store email notification history
CREATE TABLE email_notifications (
    id TEXT PRIMARY KEY,
    request_id TEXT REFERENCES reimbursement_requests(id),
    role_email TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'sent'
);
```

### 5. Email Templates

**Grand Knight Approval Template:**
```
Subject: [Council 15857] Reimbursement Voucher Approval Required - Voucher CE001

Dear Grand Knight,

A reimbursement voucher requires your approval:

Voucher Number: CE001
Requester: John Smith
Amount: $150.00
Description: Office supplies for youth program
Program: Youth Activities

To approve: [APPROVE LINK]
To reject: [REJECT LINK]

This approval link expires in 7 days.

Best regards,
KC Management System
```

**Treasurer Payment Template:**
```
Subject: [Council 15857] Payment Required - Voucher CE001

Dear Treasurer,

A reimbursement voucher has been approved and requires payment:

Voucher Number: CE001
Requester: John Smith
Amount: $150.00
Description: Office supplies for youth program

To mark as paid: [PAYMENT LINK]

This payment link expires in 7 days.

Best regards,
KC Management System
```

### 6. Configuration Options

**Admin Settings:**
- Enable/disable email-based approvals per organization
- Set email notification preferences
- Configure approval link expiration times
- Set up email service credentials

**User Preferences:**
- Choose between in-app or email notifications
- Set preferred email addresses for roles
- Configure notification frequency

### 7. Implementation Phases

**Phase 1: Foundation**
- Add email fields to user roles
- Create email templates
- Set up basic email service integration

**Phase 2: Email Workflow**
- Implement email notification sending
- Create secure approval links
- Add webhook handling for email responses

**Phase 3: Enhanced Features**
- Add email preference settings
- Implement notification history
- Add email-based audit trail

**Phase 4: Advanced Features**
- Email signature verification
- Multi-factor authentication for email approvals
- Integration with external email services

### 8. Benefits

**For Organizations:**
- **Reduced Barriers:** No registration required for approval participants
- **Familiar Workflow:** Email-based approvals are common and trusted
- **Flexibility:** Can mix registered and unregistered users
- **Audit Trail:** All approvals still tracked and documented

**For Users:**
- **Convenience:** Approve from anywhere via email
- **Familiarity:** No need to learn new app interface
- **Security:** Secure links with expiration times
- **Flexibility:** Choose preferred notification method

### 9. Potential Challenges

**Technical:**
- Email delivery reliability
- Spam filter compatibility
- Token security and management
- Webhook handling and error recovery

**User Experience:**
- Email approval UX design
- Clear communication of approval status
- Handling of expired links
- Support for users who prefer in-app workflow

**Security:**
- Email spoofing prevention
- Token hijacking protection
- Rate limiting and abuse prevention
- Compliance with data protection regulations

### 10. Success Metrics

**Adoption:**
- Percentage of organizations using email approvals
- Number of email-based approvals vs in-app approvals
- User satisfaction with email workflow

**Performance:**
- Email delivery success rate
- Approval response times
- System reliability and uptime

**Security:**
- Number of security incidents
- Token compromise attempts
- Audit trail completeness

## Conclusion

This email-based approval workflow would significantly enhance the reimbursement system's usability and adoption by removing the registration barrier for key approval participants. The implementation can be phased to minimize risk and allow for iterative improvement based on user feedback.

The approach maintains the existing in-app workflow while adding a complementary email-based option, giving organizations the flexibility to choose the method that works best for their specific needs and user preferences. 