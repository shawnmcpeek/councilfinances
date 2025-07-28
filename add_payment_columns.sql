-- Add payment method and check number columns to reimbursement_requests table
-- This allows the treasurer to specify how the voucher was paid

-- Add payment_method column
ALTER TABLE public.reimbursement_requests 
ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- Add check_number column  
ALTER TABLE public.reimbursement_requests 
ADD COLUMN IF NOT EXISTS check_number TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN public.reimbursement_requests.payment_method IS 'Payment method used (check, cash, debit_card, square)';
COMMENT ON COLUMN public.reimbursement_requests.check_number IS 'Check number if payment method is check'; 