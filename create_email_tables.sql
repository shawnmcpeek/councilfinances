-- Create email approval tokens table
CREATE TABLE IF NOT EXISTS email_approval_tokens (
    id TEXT PRIMARY KEY,
    request_id TEXT REFERENCES reimbursement_requests(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('grand_knight', 'treasurer')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    decision TEXT CHECK (decision IN ('approve', 'reject', 'pay'))
);

-- Create email notifications history table
CREATE TABLE IF NOT EXISTS email_notifications (
    id TEXT PRIMARY KEY,
    request_id TEXT REFERENCES reimbursement_requests(id) ON DELETE CASCADE,
    role_email TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'fallback_logged')),
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add email fields to organizations table
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS financial_officer_email TEXT,
ADD COLUMN IF NOT EXISTS grand_knight_email TEXT,
ADD COLUMN IF NOT EXISTS treasurer_email TEXT;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_email_approval_tokens_request_id ON email_approval_tokens(request_id);
CREATE INDEX IF NOT EXISTS idx_email_approval_tokens_expires_at ON email_approval_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_email_notifications_request_id ON email_notifications(request_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_sent_at ON email_notifications(sent_at);

-- Add RLS policies for email tables
ALTER TABLE email_approval_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- RLS policy for email_approval_tokens - users can only see tokens for their organization's requests
CREATE POLICY "Users can view email approval tokens for their organization" ON email_approval_tokens
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM reimbursement_requests rr
            WHERE rr.id = email_approval_tokens.request_id
            AND rr.organization_id IN (
                SELECT 
                    CASE 
                        WHEN u.council_number IS NOT NULL THEN 'C' || LPAD(u.council_number::text, 6, '0')
                        ELSE NULL
                    END
                FROM public.users u 
                WHERE u.id = auth.uid()::text
                UNION
                SELECT 
                    CASE 
                        WHEN u.assembly_number IS NOT NULL THEN 'A' || LPAD(u.assembly_number::text, 6, '0')
                        ELSE NULL
                    END
                FROM public.users u 
                WHERE u.id = auth.uid()::text
            )
        )
    );

-- RLS policy for email_notifications - users can only see notifications for their organization's requests
CREATE POLICY "Users can view email notifications for their organization" ON email_notifications
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM reimbursement_requests rr
            WHERE rr.id = email_notifications.request_id
            AND rr.organization_id IN (
                SELECT 
                    CASE 
                        WHEN u.council_number IS NOT NULL THEN 'C' || LPAD(u.council_number::text, 6, '0')
                        ELSE NULL
                    END
                FROM public.users u 
                WHERE u.id = auth.uid()::text
                UNION
                SELECT 
                    CASE 
                        WHEN u.assembly_number IS NOT NULL THEN 'A' || LPAD(u.assembly_number::text, 6, '0')
                        ELSE NULL
                    END
                FROM public.users u 
                WHERE u.id = auth.uid()::text
            )
        )
    );

-- RLS policy for inserting email approval tokens - only system can insert
CREATE POLICY "System can insert email approval tokens" ON email_approval_tokens
    FOR INSERT WITH CHECK (true);

-- RLS policy for inserting email notifications - only system can insert
CREATE POLICY "System can insert email notifications" ON email_notifications
    FOR INSERT WITH CHECK (true);

-- RLS policy for updating email approval tokens - only system can update
CREATE POLICY "System can update email approval tokens" ON email_approval_tokens
    FOR UPDATE USING (true);

-- Function to clean up expired tokens (run this periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_email_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM email_approval_tokens 
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql; 