-- Create reimbursement_requests table for KC Management app
-- Follows existing database patterns and conventions

CREATE TABLE IF NOT EXISTS public.reimbursement_requests (
    id TEXT PRIMARY KEY,
    organization_id TEXT NOT NULL,
    organization_type TEXT NOT NULL CHECK (organization_type IN ('council', 'assembly')),
    requester_id TEXT NOT NULL,
    requester_name TEXT NOT NULL,
    requester_email TEXT NOT NULL,
    requester_phone TEXT NOT NULL,
    program_id TEXT NOT NULL,
    program_name TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    recipient_type TEXT NOT NULL CHECK (recipient_type IN ('self', 'donation')),
    donation_entity TEXT,
                  delivery_method TEXT NOT NULL CHECK (delivery_method IN ('meeting', 'mail', 'online')),
    mailing_address TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'denied', 'voucher_created', 'gk_approved', 'paid')),
    denial_reason TEXT,
    voucher_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    denied_by TEXT,
    denied_at TIMESTAMP WITH TIME ZONE,
    voucher_created_by TEXT,
    voucher_created_at TIMESTAMP WITH TIME ZONE,
    gk_approved_by TEXT,
    gk_approved_at TIMESTAMP WITH TIME ZONE,
    paid_by TEXT,
    paid_at TIMESTAMP WITH TIME ZONE,
    document_urls TEXT[] DEFAULT '{}'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reimbursement_organization_id ON public.reimbursement_requests(organization_id);
CREATE INDEX IF NOT EXISTS idx_reimbursement_requester_id ON public.reimbursement_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_reimbursement_status ON public.reimbursement_requests(status);
CREATE INDEX IF NOT EXISTS idx_reimbursement_created_at ON public.reimbursement_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_reimbursement_voucher_number ON public.reimbursement_requests(voucher_number);

-- Enable Row Level Security
ALTER TABLE public.reimbursement_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies following existing patterns

-- Policy 1: Users can view reimbursement requests for their organizations
CREATE POLICY "Users can read organization reimbursement requests" ON public.reimbursement_requests
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        organization_id IN (
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
    );

-- Policy 2: Users can create reimbursement requests for their organizations
CREATE POLICY "Users can insert organization reimbursement requests" ON public.reimbursement_requests
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        organization_id IN (
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
        AND requester_id = auth.uid()::text
    );

-- Policy 3: Users can update their own pending reimbursement requests
CREATE POLICY "Users can update own pending reimbursement requests" ON public.reimbursement_requests
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        requester_id = auth.uid()::text
        AND status = 'pending'
    );

-- Policy 4: Financial Officers can update reimbursement requests for their organization
CREATE POLICY "Financial Officers can update reimbursement requests" ON public.reimbursement_requests
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        organization_id IN (
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
        AND (
            -- Financial Secretary or Faithful Comptroller can approve/deny
            (organization_type = 'council' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Financial Secretary' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Faithful Comptroller' = ANY(assembly_roles)
            ))
            -- Grand Knight or Faithful Navigator can approve vouchers
            OR
            (organization_type = 'council' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Grand Knight' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Faithful Navigator' = ANY(assembly_roles)
            ))
            -- Treasurer or Faithful Purser can mark as paid
            OR
            (organization_type = 'council' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Treasurer' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'Faithful Purser' = ANY(assembly_roles)
            ))
        )
    );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reimbursement_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_reimbursement_updated_at_trigger
    BEFORE UPDATE ON public.reimbursement_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_reimbursement_updated_at();

-- Create function to generate unique voucher numbers
CREATE OR REPLACE FUNCTION generate_voucher_number(org_id TEXT)
RETURNS TEXT AS $$
DECLARE
    prefix TEXT;
    next_sequence INTEGER;
BEGIN
    -- Determine prefix based on organization type
    IF org_id LIKE 'C%' THEN
        prefix := 'CE';
    ELSIF org_id LIKE 'A%' THEN
        prefix := 'AE';
    ELSE
        RAISE EXCEPTION 'Invalid organization ID format';
    END IF;
    
    -- Get the next sequence number for this organization
    SELECT COALESCE(MAX(CAST(SUBSTRING(voucher_number FROM 3) AS INTEGER)), 0) + 1
    INTO next_sequence
    FROM public.reimbursement_requests
    WHERE organization_id = org_id
    AND voucher_number IS NOT NULL
    AND voucher_number LIKE prefix || '%';
    
    -- Return formatted voucher number
    RETURN prefix || LPAD(next_sequence::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- Create function to create voucher automatically when approved
CREATE OR REPLACE FUNCTION create_voucher_on_approval()
RETURNS TRIGGER AS $$
BEGIN
    -- If status changed to 'approved', create voucher
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        NEW.voucher_number := generate_voucher_number(NEW.organization_id);
        NEW.voucher_created_by := NEW.approved_by;
        NEW.voucher_created_at := NOW();
        NEW.status := 'voucher_created';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically create voucher when approved
CREATE TRIGGER create_voucher_on_approval_trigger
    BEFORE UPDATE ON public.reimbursement_requests
    FOR EACH ROW
    EXECUTE FUNCTION create_voucher_on_approval();

-- Create function to create expense entry when marked as paid
CREATE OR REPLACE FUNCTION create_expense_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- If status changed to 'paid', create expense entry
    IF NEW.status = 'paid' AND OLD.status = 'gk_approved' THEN
        INSERT INTO public.finance_entries (
            id,
            organization_id,
            program_id,
            program_name,
            is_expense,
            amount,
            description,
            date,
            created_at,
            updated_at,
            created_by,
            updated_by
        ) VALUES (
            NEW.id || '_expense',
            NEW.organization_id,
            NEW.program_id,
            NEW.program_name,
            true,
            NEW.amount,
            'Reimbursement: ' || NEW.description || ' (Voucher: ' || NEW.voucher_number || ')',
            NOW(),
            NOW(),
            NOW(),
            NEW.paid_by,
            NEW.paid_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically create expense entry when paid
CREATE TRIGGER create_expense_on_payment_trigger
    BEFORE UPDATE ON public.reimbursement_requests
    FOR EACH ROW
    EXECUTE FUNCTION create_expense_on_payment();

-- Grant necessary permissions
GRANT ALL ON TABLE public.reimbursement_requests TO authenticated; 