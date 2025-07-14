-- Drop existing policies to ensure clean state
DO $$ 
BEGIN
    -- Drop profiles policies
    DROP POLICY IF EXISTS profiles_select_policy ON profiles;
    DROP POLICY IF EXISTS profiles_update_policy ON profiles;
    DROP POLICY IF EXISTS profiles_insert_policy ON profiles;

    -- Drop driver_details policies
    DROP POLICY IF EXISTS driver_details_select_policy ON driver_details;
    DROP POLICY IF EXISTS driver_details_update_policy ON driver_details;
    DROP POLICY IF EXISTS driver_details_insert_policy ON driver_details;

    -- Drop warehouse_details policies
    DROP POLICY IF EXISTS warehouse_details_select_policy ON warehouse_details;
    DROP POLICY IF EXISTS warehouse_details_update_policy ON warehouse_details;
    DROP POLICY IF EXISTS warehouse_details_insert_policy ON warehouse_details;

    -- Drop broker_details policies
    DROP POLICY IF EXISTS broker_details_select_policy ON broker_details;
    DROP POLICY IF EXISTS broker_details_update_policy ON broker_details;
    DROP POLICY IF EXISTS broker_details_insert_policy ON broker_details;

    -- Drop jobs policies
    DROP POLICY IF EXISTS jobs_open_select_policy ON jobs;
    DROP POLICY IF EXISTS jobs_own_select_policy ON jobs;
    DROP POLICY IF EXISTS jobs_insert_policy ON jobs;
    DROP POLICY IF EXISTS jobs_owner_update_policy ON jobs;
    DROP POLICY IF EXISTS jobs_driver_update_policy ON jobs;

    -- Drop job_applications policies
    DROP POLICY IF EXISTS applications_select_policy ON job_applications;
    DROP POLICY IF EXISTS applications_insert_policy ON job_applications;
    DROP POLICY IF EXISTS applications_driver_update_policy ON job_applications;
    DROP POLICY IF EXISTS applications_owner_update_policy ON job_applications;
    DROP POLICY IF EXISTS applications_delete_policy ON job_applications;
EXCEPTION
    WHEN others THEN null;
END $$;

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Grant access to authenticated users
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.driver_details TO authenticated;
GRANT ALL ON public.warehouse_details TO authenticated;
GRANT ALL ON public.broker_details TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_applications TO authenticated;

-- Profiles table policies
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT
    USING (
        id = auth.uid() OR
        id IN (
            SELECT assigned_driver_id FROM jobs WHERE warehouse_owner_id = auth.uid()
            UNION
            SELECT warehouse_owner_id FROM jobs WHERE assigned_driver_id = auth.uid()
        )
    );

CREATE POLICY "profiles_update_policy" ON profiles
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_insert_policy" ON profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());

-- Driver details table policies
CREATE POLICY "driver_details_select_policy" ON driver_details
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT assigned_driver_id 
            FROM jobs 
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "driver_details_update_policy" ON driver_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "driver_details_insert_policy" ON driver_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Warehouse details table policies
CREATE POLICY "warehouse_details_select_policy" ON warehouse_details
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT warehouse_owner_id 
            FROM jobs 
            WHERE assigned_driver_id = auth.uid()
        )
    );

CREATE POLICY "warehouse_details_update_policy" ON warehouse_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "warehouse_details_insert_policy" ON warehouse_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Broker details table policies
CREATE POLICY "broker_details_select_policy" ON broker_details
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "broker_details_update_policy" ON broker_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "broker_details_insert_policy" ON broker_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Jobs table policies
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    USING (status = 'open');

CREATE POLICY "jobs_own_select_policy" ON jobs
    FOR SELECT
    USING (
        warehouse_owner_id = auth.uid() OR
        assigned_driver_id = auth.uid()
    );

CREATE POLICY "jobs_insert_policy" ON jobs
    FOR INSERT
    WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'warehouse_owner'
        )
    );

CREATE POLICY "jobs_owner_update_policy" ON jobs
    FOR UPDATE
    USING (warehouse_owner_id = auth.uid());

CREATE POLICY "jobs_driver_update_policy" ON jobs
    FOR UPDATE
    USING (
        assigned_driver_id = auth.uid() AND
        status IN ('in_progress', 'completed')
    )
    WITH CHECK (
        assigned_driver_id = auth.uid() AND
        status IN ('in_progress', 'completed')
    );

-- Job applications table policies
CREATE POLICY "applications_select_policy" ON job_applications
    FOR SELECT
    USING (
        driver_id = auth.uid() OR
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_insert_policy" ON job_applications
    FOR INSERT
    WITH CHECK (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'driver'
        )
    );

CREATE POLICY "applications_driver_update_policy" ON job_applications
    FOR UPDATE
    USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());

CREATE POLICY "applications_owner_update_policy" ON job_applications
    FOR UPDATE
    USING (
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_delete_policy" ON job_applications
    FOR DELETE
    USING (
        driver_id = auth.uid() AND
        status = 'pending'
    );

-- Add indexes for policy performance
CREATE INDEX IF NOT EXISTS idx_jobs_warehouse_owner ON jobs(warehouse_owner_id);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_driver ON jobs(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_applications_driver ON job_applications(driver_id);
CREATE INDEX IF NOT EXISTS idx_applications_job ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_details_user ON driver_details(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_details_user ON warehouse_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_details_user ON broker_details(user_id); 