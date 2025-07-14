-- Create a backup of the jobs table
CREATE TABLE jobs_backup AS SELECT * FROM jobs;

-- Drop the existing enum type and constraints
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;
DROP TYPE IF EXISTS job_status_new CASCADE;

-- Create the new enum type
CREATE TYPE job_status_new AS ENUM (
    'open',
    'assigned',
    'awaitingPickupVerification',
    'inTransit',
    'completed',
    'cancelled'
);

-- Create a new jobs table with the correct enum type
CREATE TABLE jobs_new (
    LIKE jobs INCLUDING ALL
);

-- Copy data from the old table to the new table
INSERT INTO jobs_new 
SELECT 
    id,
    warehouse_owner_id,
    assigned_driver_id,
    title,
    description,
    goods_type,
    weight,
    price,
    pickup_location,
    destination,
    distance,
    posted_date,
    assigned_date,
    completion_date,
    created_at,
    updated_at,
    pickup_verified_at,
    pickup_verified_by,
    delivery_verified_at,
    delivery_verified_by,
    CASE 
        WHEN jobs.job_status = 'in_progress' THEN 'inTransit'
        ELSE jobs.job_status
    END as job_status,
    assigned_driver_name
FROM jobs;

-- Alter the job_status column to use the new enum type
ALTER TABLE jobs_new 
    ALTER COLUMN job_status TYPE job_status_new USING job_status::job_status_new;

-- Drop the old table and rename the new one
DROP TABLE jobs;
ALTER TABLE jobs_new RENAME TO jobs;

-- Add the constraint back
ALTER TABLE jobs
    ALTER COLUMN job_status SET DEFAULT 'open'::job_status_new,
    ADD CONSTRAINT jobs_status_check 
    CHECK (job_status IN ('open', 'assigned', 'awaitingPickupVerification', 'inTransit', 'completed', 'cancelled'));

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
        AND job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
    );
END;
$$;

-- Drop the backup table if everything is successful
DROP TABLE jobs_backup; 