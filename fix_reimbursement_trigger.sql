-- Fix the reimbursement trigger function to use correct field names
-- This fixes the "column 'type' of relation 'finance_entries' does not exist" error

-- Drop the existing trigger first
DROP TRIGGER IF EXISTS create_expense_on_payment_trigger ON public.reimbursement_requests;

-- Drop the existing function
DROP FUNCTION IF EXISTS create_expense_on_payment();

-- Create the corrected function
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
            payment_method,
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
            'Check',
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

-- Recreate the trigger
CREATE TRIGGER create_expense_on_payment_trigger
    BEFORE UPDATE ON public.reimbursement_requests
    FOR EACH ROW
    EXECUTE FUNCTION create_expense_on_payment(); 