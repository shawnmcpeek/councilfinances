-- Fix organizations table for KC Management app

-- Create organizations table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.organizations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('council', 'assembly')),
    jurisdiction TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add jurisdiction column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'organizations' AND column_name = 'jurisdiction') THEN
        ALTER TABLE public.organizations ADD COLUMN jurisdiction TEXT;
    END IF;
END $$;

-- Add the missing organizations
INSERT INTO public.organizations (id, name, type, jurisdiction) VALUES
    ('C015857', 'Council #15857', 'council', 'TN'),
    ('A000094', 'Assembly #94', 'assembly', 'TN')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    jurisdiction = EXCLUDED.jurisdiction,
    updated_at = NOW();

-- Enable Row Level Security (RLS)
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.organizations;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON public.organizations;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON public.organizations;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON public.organizations;

-- Create RLS policies for organizations table
CREATE POLICY "Enable read access for authenticated users" ON public.organizations
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON public.organizations
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON public.organizations
    FOR DELETE USING (auth.role() = 'authenticated'); 