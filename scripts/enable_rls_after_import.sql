-- Re-enable RLS for finance_entries table after CSV import
-- This should be run after importing data

-- Re-enable RLS
ALTER TABLE public.finance_entries ENABLE ROW LEVEL SECURITY; 