-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create job_status_new enum type
CREATE TYPE job_status_new AS ENUM (
    'open',
    'assigned',
    'awaitingPickupVerification',
    'inTransit',
    'awaitingDeliveryVerification',
    'completed',
    'cancelled'
);

-- Create application_status enum type
CREATE TYPE application_status AS ENUM (
    'pending',
    'accepted',
    'rejected'
);

-- Create broker_driver_status enum type
CREATE TYPE broker_driver_status AS ENUM (
    'pending',
    'active',
    'rejected',
    'removed'
);

-- Create profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('driver', 'warehouse_owner', 'broker')),
    address TEXT,
    city TEXT,
    state TEXT,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now())
);

-- Create driver details table
CREATE TABLE public.driver_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    license_number TEXT,
    license_expiry DATE,
    vehicle_type TEXT,
    experience_years INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create warehouse details table
CREATE TABLE public.warehouse_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    warehouse_name TEXT,
    storage_capacity DECIMAL,
    operating_hours TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create broker details table
CREATE TABLE public.broker_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    company_name TEXT,
    registration_number TEXT,
    years_in_business INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create jobs table
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    goods_type TEXT NOT NULL,
    weight DECIMAL NOT NULL,
    weight_unit TEXT DEFAULT 'kg', -- e.g. kg, lb
    price DECIMAL NOT NULL,
    price_currency TEXT DEFAULT 'INR', -- e.g. INR, USD
    vehicle_type TEXT, -- e.g. Truck, Van
    pickup_location TEXT NOT NULL,
    pickup_lat DECIMAL,
    pickup_lng DECIMAL,
    destination TEXT NOT NULL,
    destination_lat DECIMAL,
    destination_lng DECIMAL,
    distance DECIMAL NOT NULL,
    scheduled_pickup_time TIMESTAMPTZ,
    estimated_duration INTERVAL,
    job_status job_status_new DEFAULT 'open',
    posted_date TIMESTAMPTZ DEFAULT timezone('utc', now()),
    assigned_driver_id UUID REFERENCES profiles(id),
    assigned_driver_name TEXT,
    assigned_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    pickup_verified_at TIMESTAMPTZ,
    pickup_verified_by UUID REFERENCES profiles(id),
    delivery_verified_at TIMESTAMPTZ,
    delivery_verified_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_pickup_location ON jobs(pickup_location);
CREATE INDEX IF NOT EXISTS idx_jobs_destination ON jobs(destination);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs(posted_date);
CREATE INDEX IF NOT EXISTS idx_jobs_owner_status ON jobs(warehouse_owner_id, job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_driver_status ON jobs(assigned_driver_id, job_status);

-- Create job applications table
CREATE TABLE public.job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status application_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(job_id, driver_id)
);

-- Create broker-driver relationship table
CREATE TABLE public.broker_drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    broker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status broker_driver_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(broker_id, driver_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_drivers ENABLE ROW LEVEL SECURITY;

-- Grant access to authenticated users
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.driver_details TO authenticated;
GRANT ALL ON public.warehouse_details TO authenticated;
GRANT ALL ON public.broker_details TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_applications TO authenticated;
GRANT ALL ON public.broker_drivers TO authenticated;

-- Create private schema for security functions
CREATE SCHEMA IF NOT EXISTS private;

-- Create security function for job relationships
CREATE OR REPLACE FUNCTION private.check_job_relationship(profile_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM jobs 
        WHERE (warehouse_owner_id = auth.uid() AND assigned_driver_id = profile_id)
           OR (assigned_driver_id = auth.uid() AND warehouse_owner_id = profile_id)
    );
END;
$$;

-- Create function to check for active jobs
CREATE OR REPLACE FUNCTION private.has_active_job(driver_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM jobs
        WHERE assigned_driver_id = driver_id
        AND job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
    );
END;
$$;

-- Create function to check if a job is available for application
CREATE OR REPLACE FUNCTION private.can_apply_for_job(job_id uuid, driver_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if job exists and is open
    IF NOT EXISTS (
        SELECT 1 FROM jobs 
        WHERE id = job_id 
        AND job_status = 'open'
    ) THEN
        RETURN false;
    END IF;

    -- Check if driver already has an active job
    IF private.has_active_job(driver_id) THEN
        RETURN false;
    END IF;

    -- Check if driver has already applied
    IF EXISTS (
        SELECT 1 FROM job_applications
        WHERE job_id = job_id
        AND driver_id = driver_id
    ) THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "jobs_owner_update_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_driver_update_policy" ON jobs;

-- Create updated policies for warehouse owners
CREATE POLICY "jobs_owner_update_policy" ON jobs
    FOR UPDATE USING (
        warehouse_owner_id = auth.uid() AND
        job_status IN ('awaitingDeliveryVerification', 'awaitingPickupVerification')
    )
    WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        job_status IN ('completed', 'inTransit')
    );

-- Create updated policies for drivers
CREATE POLICY "jobs_driver_update_policy" ON jobs
    FOR UPDATE USING (
        assigned_driver_id = auth.uid() AND
        job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification')
    )
    WITH CHECK (
        assigned_driver_id = auth.uid() AND
        job_status IN ('awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification')
    );

-- Drop and recreate the trigger function
DROP TRIGGER IF EXISTS validate_job_status_transition ON jobs;

CREATE OR REPLACE FUNCTION private.validate_job_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- If status hasn't changed, allow the update
    IF NEW.job_status = OLD.job_status THEN
        RETURN NEW;
    END IF;

    -- Validate the status transition
    IF NOT (
        -- Warehouse owner transitions
        (OLD.job_status = 'awaitingDeliveryVerification' AND NEW.job_status = 'completed' AND NEW.warehouse_owner_id = auth.uid()) OR
        (OLD.job_status = 'awaitingPickupVerification' AND NEW.job_status = 'inTransit' AND NEW.warehouse_owner_id = auth.uid()) OR
        -- Driver transitions
        (OLD.job_status = 'assigned' AND NEW.job_status = 'awaitingPickupVerification' AND NEW.assigned_driver_id = auth.uid()) OR
        (OLD.job_status = 'awaitingPickupVerification' AND NEW.job_status = 'inTransit' AND NEW.assigned_driver_id = auth.uid()) OR
        (OLD.job_status = 'inTransit' AND NEW.job_status = 'awaitingDeliveryVerification' AND NEW.assigned_driver_id = auth.uid()) OR
        -- Cancellation (both can do)
        (OLD.job_status IN ('open', 'assigned', 'awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification') AND 
         NEW.job_status = 'cancelled' AND 
         (NEW.warehouse_owner_id = auth.uid() OR NEW.assigned_driver_id = auth.uid()))
    ) THEN
        RAISE EXCEPTION 'Invalid job status transition from % to %', OLD.job_status, NEW.job_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER validate_job_status_transition
    BEFORE UPDATE OF job_status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION private.validate_job_status_transition();

-- Add helpful comments
COMMENT ON COLUMN jobs.job_status IS 'Current status of the job (open, assigned, awaitingPickupVerification, inTransit, awaitingDeliveryVerification, completed, cancelled)';

-- Profiles Policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "enable_insert_for_authenticated" ON profiles;

-- Allow service role full access
CREATE POLICY "service_role_policy" ON profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- More permissive insert policy
CREATE POLICY "profiles_insert_policy" ON profiles 
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "profiles_select_policy" ON profiles 
    FOR SELECT 
    TO authenticated
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE 
                (warehouse_owner_id = auth.uid() AND assigned_driver_id = profiles.id)
                OR 
                (assigned_driver_id = auth.uid() AND warehouse_owner_id = profiles.id)
        )
    );

CREATE POLICY "profiles_update_policy" ON profiles 
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, authenticated, service_role;

-- Create index for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- Driver Details Policies
CREATE POLICY "driver_details_select_policy" ON driver_details
    FOR SELECT USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT assigned_driver_id 
            FROM jobs 
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "driver_details_update_policy" ON driver_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "driver_details_insert_policy" ON driver_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Warehouse Details Policies
CREATE POLICY "warehouse_details_select_policy" ON warehouse_details
    FOR SELECT USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT warehouse_owner_id 
            FROM jobs 
            WHERE assigned_driver_id = auth.uid()
        )
    );

CREATE POLICY "warehouse_details_update_policy" ON warehouse_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "warehouse_details_insert_policy" ON warehouse_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Broker Details Policies
CREATE POLICY "broker_details_select_policy" ON broker_details
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "broker_details_update_policy" ON broker_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "broker_details_insert_policy" ON broker_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Jobs Policies
DROP POLICY IF EXISTS "jobs_open_select_policy" ON jobs;
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    TO authenticated, anon
    USING (job_status = 'open');

DROP POLICY IF EXISTS "jobs_own_select_policy" ON jobs;
CREATE POLICY "jobs_own_select_policy" ON jobs
    FOR SELECT USING (
        warehouse_owner_id = auth.uid() OR
        assigned_driver_id = auth.uid()
    );

DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
CREATE POLICY "jobs_insert_policy" ON jobs
    FOR INSERT WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'warehouse_owner'
        )
    );

DROP POLICY IF EXISTS "drivers_can_apply_for_jobs" ON job_applications;
CREATE POLICY "drivers_can_apply_for_jobs"
ON job_applications
FOR INSERT
TO authenticated
WITH CHECK (
    driver_id = (SELECT auth.uid()) AND
    private.can_apply_for_job(job_id, driver_id)
);

-- Job Applications Policies
CREATE POLICY "applications_select_policy" ON job_applications
    FOR SELECT USING (
        driver_id = auth.uid() OR
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_insert_policy" ON job_applications
    FOR INSERT WITH CHECK (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'driver'
        )
    );

CREATE POLICY "applications_driver_update_policy" ON job_applications
    FOR UPDATE USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());

CREATE POLICY "applications_owner_update_policy" ON job_applications
    FOR UPDATE USING (
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_delete_policy" ON job_applications
    FOR DELETE USING (
        driver_id = auth.uid() AND
        status = 'pending'
    );

-- Broker-Driver Relationship Policies
CREATE POLICY "broker_drivers_select_policy" ON broker_drivers
    FOR SELECT USING (
        broker_id = auth.uid() OR
        driver_id = auth.uid()
    );

CREATE POLICY "broker_drivers_insert_policy" ON broker_drivers
    FOR INSERT WITH CHECK (
        broker_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'broker'
        )
    );

CREATE POLICY "broker_drivers_update_policy" ON broker_drivers
    FOR UPDATE USING (broker_id = auth.uid() OR driver_id = auth.uid());

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);
CREATE INDEX IF NOT EXISTS idx_driver_details_user_id ON driver_details(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_details_user_id ON warehouse_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_details_user_id ON broker_details(user_id);
CREATE INDEX IF NOT EXISTS idx_jobs_warehouse_owner ON jobs(warehouse_owner_id);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_driver ON jobs(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_job_applications_job ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_driver ON job_applications(driver_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_broker ON broker_drivers(broker_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_driver ON broker_drivers(driver_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_status ON broker_drivers(status);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jobs_owner_status ON jobs(warehouse_owner_id, job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_driver_status ON jobs(assigned_driver_id, job_status);
CREATE INDEX IF NOT EXISTS idx_applications_job_status ON job_applications(job_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_driver_status ON job_applications(driver_id, status);