# Database Schema Reference

## Tables and Columns

### users
- `id` (text) - Primary key, user ID
- `first_name` (text)
- `last_name` (text)
- `membership_number` (integer)
- `council_number` (integer) - Required
- `assembly_number` (integer) - Optional
- `council_roles` (text[]) - Array of council roles
- `assembly_roles` (text[]) - Array of assembly roles
- `jurisdiction` (text) - Default 'TN'

### organizations
- `id` (text) - Primary key, format: C015857 or A000094
- `name` (text) - e.g., "Council #15857"
- `type` (text) - 'council' or 'assembly'
- `jurisdiction` (text)
- `created_at` (timestamp with time zone)
- `updated_at` (timestamp with time zone)

### programs
- `id` (text) - Primary key
- `name` (text)
- `category` (text) - 'FAITH', 'FAMILY', 'COMMUNITY', 'LIFE', 'COUNCIL', 'ASSEMBLY', etc.
- `is_system_default` (boolean)
- `financial_type` (text) - 'expenseOnly', 'incomeOnly', 'both'
- `is_enabled` (boolean)
- `is_assembly` (boolean)
- `organization_id` (text) - Foreign key to organizations.id

### budget_entries
- `id` (text) - Primary key
- `organization_id` (text) - Foreign key to organizations.id
- `program_id` (text) - Foreign key to programs.id
- `income` (numeric)
- `expenses` (numeric)
- `created_at` (timestamp without time zone)
- `updated_at` (timestamp without time zone)
- `created_by` (text) - User ID who created the entry
- `updated_by` (text) - User ID who last updated the entry
- `status` (text)

### finance_entries
- `id` (text) - Primary key
- `organization_id` (text) - Foreign key to organizations.id
- `date` (timestamp without time zone)
- `program_id` (text) - Foreign key to programs.id
- `program_name` (text)
- `amount` (numeric)
- `payment_method` (text)
- `check_number` (text)
- `description` (text)
- `is_expense` (boolean)
- `created_at` (timestamp without time zone)
- `updated_at` (timestamp without time zone)
- `created_by` (text) - User ID who created the entry
- `updated_by` (text) - User ID who last updated the entry

### hours_entries
- `id` (text) - Primary key
- `user_id` (text) - Foreign key to users.id
- `organization_id` (text) - Foreign key to organizations.id
- `is_assembly` (boolean)
- `program_id` (text) - Foreign key to programs.id
- `program_name` (text)
- `category` (text)
- `start_time` (timestamp without time zone)
- `end_time` (timestamp without time zone)
- `total_hours` (numeric)
- `disbursement` (numeric)
- `description` (text)
- `created_at` (timestamp without time zone)
- `updated_at` (timestamp without time zone)

### program_entries
- `id` (text) - Primary key
- `organization_id` (text) - Foreign key to organizations.id
- `year` (text)
- `category` (text)
- `program_id` (text) - Foreign key to programs.id
- `program_name` (text)
- `hours` (integer) - Default 0
- `disbursement` (numeric) - Default 0
- `created` (timestamp without time zone)
- `last_updated` (timestamp without time zone)
- `entries` (jsonb) - Default '[]'::jsonb

## Organization ID Format
- Council: `C` + 6-digit zero-padded number (e.g., `C015857`)
- Assembly: `A` + 6-digit zero-padded number (e.g., `A000094`)

## Notes
- All tables have Row Level Security (RLS) enabled
- User authentication uses Supabase Auth with UUID user IDs
- Organization relationships are determined by council_number and assembly_number in users table
- Programs can be system defaults or custom programs created by organizations 