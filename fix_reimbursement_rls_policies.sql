-- Fix RLS policies for reimbursement_requests table
-- The role names in the policies need to match the actual enum values

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read organization reimbursement requests" ON public.reimbursement_requests;
DROP POLICY IF EXISTS "Users can insert organization reimbursement requests" ON public.reimbursement_requests;
DROP POLICY IF EXISTS "Users can update own pending reimbursement requests" ON public.reimbursement_requests;
DROP POLICY IF EXISTS "Financial Officers can update reimbursement requests" ON public.reimbursement_requests;

-- Recreate policies with correct role names

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
                AND 'financialSecretary' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'faithfulComptroller' = ANY(assembly_roles)
            ))
            -- Grand Knight or Faithful Navigator can approve vouchers
            OR
            (organization_type = 'council' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'grandKnight' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'faithfulNavigator' = ANY(assembly_roles)
            ))
            -- Treasurer or Faithful Purser can mark as paid
            OR
            (organization_type = 'council' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'treasurer' = ANY(council_roles)
            ))
            OR
            (organization_type = 'assembly' AND EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid()::text 
                AND 'faithfulPurser' = ANY(assembly_roles)
            ))
        )
    ); 