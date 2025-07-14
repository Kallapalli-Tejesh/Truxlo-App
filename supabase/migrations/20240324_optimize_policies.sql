-- Create private schema
CREATE SCHEMA IF NOT EXISTS private;

-- Drop existing policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS profiles_select_policy ON profiles;
    DROP POLICY IF EXISTS jobs_open_select_policy ON jobs;
    DROP POLICY IF EXISTS jobs_own_select_policy ON jobs;
    DROP POLICY IF EXISTS driver_details_select_policy ON driver_details;
    DROP POLICY IF EXISTS warehouse_details_select_policy ON warehouse_details;
    DROP POLICY IF EXISTS broker_details_select_policy ON broker_details;
EXCEPTION
    WHEN others THEN null;
END $$;

-- Create security definer function for job relationships
CREATE OR REPLACE FUNCTION private.check_job_relationship(profile_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM jobs 
        WHERE (warehouse_owner_id = (SELECT auth.uid()) AND assigned_driver_id = profile_id)
           OR (assigned_driver_id = (SELECT auth.uid()) AND warehouse_owner_id = profile_id)
    );
END;
$$;

-- Create optimized policies
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT 
    TO authenticated, anon
    USING (
        id = (SELECT auth.uid()) OR
        private.check_job_relationship(id)
    );

CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    TO authenticated, anon
    USING (status = 'open');

CREATE POLICY "jobs_own_select_policy" ON jobs
    FOR SELECT
    TO authenticated
    USING (
        warehouse_owner_id = (SELECT auth.uid()) OR
        assigned_driver_id = (SELECT auth.uid())
    );

CREATE POLICY "driver_details_select_policy" ON driver_details
    FOR SELECT
    TO authenticated
    USING (
        user_id = (SELECT auth.uid()) OR
        user_id IN (
            SELECT assigned_driver_id 
            FROM jobs 
            WHERE warehouse_owner_id = (SELECT auth.uid())
        )
    );

CREATE POLICY "warehouse_details_select_policy" ON warehouse_details
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY "broker_details_select_policy" ON broker_details
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- Add performance indexes
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_jobs_warehouse_owner ON jobs(warehouse_owner_id);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_driver ON jobs(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_driver_details_user ON driver_details(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_details_user ON warehouse_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_details_user ON broker_details(user_id); 