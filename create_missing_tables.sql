-- Create missing tables for KC Management app

-- Program States table - stores which programs are active/inactive per organization
CREATE TABLE IF NOT EXISTS public.program_states (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizationId TEXT NOT NULL,
    isAssembly BOOLEAN NOT NULL DEFAULT false,
    programId TEXT NOT NULL,
    programName TEXT NOT NULL,
    category TEXT NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Custom Programs table - stores custom programs created by organizations
CREATE TABLE IF NOT EXISTS public.custom_programs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizationId TEXT NOT NULL,
    isAssembly BOOLEAN NOT NULL DEFAULT false,
    programName TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    isActive BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_program_states_org ON public.program_states(organizationId, isAssembly);
CREATE INDEX IF NOT EXISTS idx_custom_programs_org ON public.custom_programs(organizationId, isAssembly);

-- Enable Row Level Security (RLS)
ALTER TABLE public.program_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_programs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (basic - you may want to customize these)
CREATE POLICY "Enable read access for authenticated users" ON public.program_states
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON public.program_states
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON public.program_states
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON public.program_states
    FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON public.custom_programs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON public.custom_programs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON public.custom_programs
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON public.custom_programs
    FOR DELETE USING (auth.role() = 'authenticated'); 