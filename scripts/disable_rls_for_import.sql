-- Temporarily disable RLS for finance_entries table to allow CSV import
-- This should be run before importing data, then re-enabled after

-- Disable RLS
ALTER TABLE public.finance_entries DISABLE ROW LEVEL SECURITY;

-- After import is complete, re-enable RLS with:
-- ALTER TABLE public.finance_entries ENABLE ROW LEVEL SECURITY; 