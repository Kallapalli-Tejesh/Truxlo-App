-- First, update any existing jobs with old status values
UPDATE jobs
SET status = 'inTransit'
WHERE status = 'in_progress';

-- Drop existing type if exists and create new one
DROP TYPE IF EXISTS job_status_new CASCADE;
CREATE TYPE job_status_new AS ENUM (
    'open',
    'assigned',
    'awaitingPickupVerification',
    'inTransit',
    'completed',
    'cancelled'
);

-- Alter the jobs table to use the new enum
ALTER TABLE jobs
    ALTER COLUMN status TYPE job_status_new USING status::job_status_new;

-- Add constraint to jobs table
ALTER TABLE jobs
    ALTER COLUMN status SET DEFAULT 'open'::job_status_new,
    ADD CONSTRAINT jobs_status_check 
    CHECK (status IN ('open', 'assigned', 'awaitingPickupVerification', 'inTransit', 'completed', 'cancelled'));

-- Update the has_active_job function
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
        AND status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
    );
END;
$$; 