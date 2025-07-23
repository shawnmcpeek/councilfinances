-- Correct RLS Policies for KC Management App
-- All policies require authentication
-- Hours entries are user-specific (only owner can access)
-- All other tables are organization-specific (users can access their organization's data)

-- ===========================================
-- HOURS_ENTRIES - User-specific access only
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their hours entries" ON public.hours_entries;
DROP POLICY IF EXISTS "Users can read their organization hours entries" ON public.hours_entries;

-- Users can only read their own hours entries
CREATE POLICY "Users can read own hours entries" ON public.hours_entries
    FOR SELECT USING (auth.uid()::text = user_id);

-- Users can only insert their own hours entries
CREATE POLICY "Users can insert own hours entries" ON public.hours_entries
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Users can only update their own hours entries
CREATE POLICY "Users can update own hours entries" ON public.hours_entries
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Users can only delete their own hours entries
CREATE POLICY "Users can delete own hours entries" ON public.hours_entries
    FOR DELETE USING (auth.uid()::text = user_id);

-- ===========================================
-- FINANCE_ENTRIES - Organization-specific access
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their finance entries" ON public.finance_entries;
DROP POLICY IF EXISTS "Users can read their organization finance entries" ON public.finance_entries;

-- Users can read finance entries for their organizations
CREATE POLICY "Users can read organization finance entries" ON public.finance_entries
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

-- Users can insert finance entries for their organizations
CREATE POLICY "Users can insert organization finance entries" ON public.finance_entries
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
    );

-- Users can update finance entries for their organizations
CREATE POLICY "Users can update organization finance entries" ON public.finance_entries
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
    );

-- Users can delete finance entries for their organizations
CREATE POLICY "Users can delete organization finance entries" ON public.finance_entries
    FOR DELETE USING (
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

-- ===========================================
-- BUDGET_ENTRIES - Organization-specific access
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their budget entries" ON public.budget_entries;
DROP POLICY IF EXISTS "Users can read their organization budget entries" ON public.budget_entries;

-- Users can read budget entries for their organizations
CREATE POLICY "Users can read organization budget entries" ON public.budget_entries
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

-- Users can insert budget entries for their organizations
CREATE POLICY "Users can insert organization budget entries" ON public.budget_entries
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
    );

-- Users can update budget entries for their organizations
CREATE POLICY "Users can update organization budget entries" ON public.budget_entries
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
    );

-- Users can delete budget entries for their organizations
CREATE POLICY "Users can delete organization budget entries" ON public.budget_entries
    FOR DELETE USING (
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

-- ===========================================
-- PROGRAMS - Organization-specific access
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their organization programs" ON public.programs;
DROP POLICY IF EXISTS "Users can read their organization programs" ON public.programs;

-- Users can read programs for their organizations
CREATE POLICY "Users can read organization programs" ON public.programs
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        (is_system_default = true OR organization_id IN (
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
        ))
    );

-- Users can insert programs for their organizations
CREATE POLICY "Users can insert organization programs" ON public.programs
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
    );

-- Users can update programs for their organizations
CREATE POLICY "Users can update organization programs" ON public.programs
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
    );

-- Users can delete programs for their organizations
CREATE POLICY "Users can delete organization programs" ON public.programs
    FOR DELETE USING (
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

-- ===========================================
-- PROGRAM_ENTRIES - Organization-specific access
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.program_entries;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON public.program_entries;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON public.program_entries;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON public.program_entries;

-- Users can read program entries for their organizations
CREATE POLICY "Users can read organization program entries" ON public.program_entries
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

-- Users can insert program entries for their organizations
CREATE POLICY "Users can insert organization program entries" ON public.program_entries
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
    );

-- Users can update program entries for their organizations
CREATE POLICY "Users can update organization program entries" ON public.program_entries
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
    );

-- Users can delete program entries for their organizations
CREATE POLICY "Users can delete organization program entries" ON public.program_entries
    FOR DELETE USING (
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

-- ===========================================
-- ORGANIZATIONS - Organization-specific access
-- ===========================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their organizations" ON public.organizations;

-- Users can read their organizations
CREATE POLICY "Users can read their organizations" ON public.organizations
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        id IN (
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

-- Users can insert organizations (for auto-creation)
CREATE POLICY "Users can insert organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Users can update their organizations
CREATE POLICY "Users can update their organizations" ON public.organizations
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        id IN (
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

-- Users can delete their organizations
CREATE POLICY "Users can delete their organizations" ON public.organizations
    FOR DELETE USING (
        auth.role() = 'authenticated' AND
        id IN (
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