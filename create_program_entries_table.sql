-- Create program_entries table for tracking charitable activities
CREATE TABLE IF NOT EXISTS public.program_entries (
    id text PRIMARY KEY,
    organization_id text NOT NULL,
    year text NOT NULL,
    category text NOT NULL,
    program_id text NOT NULL,
    program_name text NOT NULL,
    hours integer DEFAULT 0,
    disbursement numeric DEFAULT 0,
    created timestamp without time zone DEFAULT now(),
    last_updated timestamp without time zone DEFAULT now(),
    entries jsonb DEFAULT '[]'::jsonb
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_program_entries_org_year ON public.program_entries(organization_id, year);
CREATE INDEX IF NOT EXISTS idx_program_entries_program ON public.program_entries(program_id);
CREATE INDEX IF NOT EXISTS idx_program_entries_category ON public.program_entries(category);

-- Enable RLS
ALTER TABLE public.program_entries ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Enable read access for authenticated users" ON public.program_entries
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON public.program_entries
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON public.program_entries
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON public.program_entries
    FOR DELETE USING (auth.role() = 'authenticated'); 