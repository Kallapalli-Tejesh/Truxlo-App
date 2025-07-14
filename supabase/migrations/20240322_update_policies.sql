-- Drop existing policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS enable_read_own_profile ON profiles;
    DROP POLICY IF EXISTS enable_update_own_profile ON profiles;
    DROP POLICY IF EXISTS enable_insert_own_profile ON profiles;
    DROP POLICY IF EXISTS profiles_select_policy ON profiles;
EXCEPTION
    WHEN others THEN null;
END $$;

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY profiles_select_policy ON profiles
    FOR SELECT
    TO authenticated
    USING (
        id = auth.uid() OR  -- User can read their own profile
        id IN (             -- Or profiles they interact with through jobs
            SELECT assigned_driver_id FROM jobs WHERE warehouse_owner_id = auth.uid()
            UNION
            SELECT warehouse_owner_id FROM jobs WHERE assigned_driver_id = auth.uid()
        )
    );

CREATE POLICY profiles_update_policy ON profiles
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY profiles_insert_policy ON profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (id = auth.uid());

-- Grant permissions
GRANT ALL ON public.profiles TO authenticated;

-- Enable RLS on role-specific tables
ALTER TABLE public.driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_details ENABLE ROW LEVEL SECURITY;

-- Create policies for role-specific tables
CREATE POLICY driver_details_select_policy ON driver_details
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY warehouse_details_select_policy ON warehouse_details
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY broker_details_select_policy ON broker_details
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Grant permissions for role-specific tables
GRANT ALL ON public.driver_details TO authenticated;
GRANT ALL ON public.warehouse_details TO authenticated;
GRANT ALL ON public.broker_details TO authenticated; 