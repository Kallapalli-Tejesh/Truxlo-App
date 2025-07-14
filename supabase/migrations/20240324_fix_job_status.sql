-- First, let's create a function to check for active jobs
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

-- Function to check if a job is available for application
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
        AND status = 'open'
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

-- Update or create job application policies
CREATE POLICY "drivers_can_apply_for_jobs"
ON job_applications
FOR INSERT
TO authenticated
WITH CHECK (
    driver_id = (SELECT auth.uid()) AND
    private.can_apply_for_job(job_id, driver_id)
);

-- Update jobs policies for status transitions
CREATE POLICY "warehouse_owners_can_assign_jobs"
ON jobs
FOR UPDATE
TO authenticated
USING (
    warehouse_owner_id = (SELECT auth.uid()) AND
    job_status = 'open'
)
WITH CHECK (
    warehouse_owner_id = (SELECT auth.uid()) AND
    job_status = 'assigned'
);

CREATE POLICY "drivers_can_update_job_status"
ON jobs
FOR UPDATE
TO authenticated
USING (
    assigned_driver_id = (SELECT auth.uid()) AND
    job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
)
WITH CHECK (
    assigned_driver_id = (SELECT auth.uid()) AND
    (
        (job_status = 'awaitingPickupVerification' AND OLD.job_status = 'assigned') OR
        (job_status = 'inTransit' AND OLD.job_status = 'awaitingPickupVerification') OR
        (job_status = 'completed' AND OLD.job_status = 'inTransit')
    )
);

-- Update the jobs open select policy to use correct status
DROP POLICY IF EXISTS "jobs_open_select_policy" ON jobs;
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    TO authenticated, anon
    USING (job_status = 'open');

-- Add an index on job status if not exists
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);

-- Add trigger to validate status transitions
CREATE OR REPLACE FUNCTION private.validate_job_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- If status hasn't changed, allow the update
    IF NEW.job_status = OLD.job_status THEN
        RETURN NEW;
    END IF;

    -- Validate the status transition
    IF NOT (
        (OLD.job_status = 'open' AND NEW.job_status = 'assigned') OR
        (OLD.job_status = 'assigned' AND NEW.job_status = 'awaitingPickupVerification') OR
        (OLD.job_status = 'awaitingPickupVerification' AND NEW.job_status = 'inTransit') OR
        (OLD.job_status = 'inTransit' AND NEW.job_status = 'completed') OR
        (OLD.job_status IN ('open', 'assigned', 'awaitingPickupVerification', 'inTransit') AND NEW.job_status = 'cancelled')
    ) THEN
        RAISE EXCEPTION 'Invalid job status transition from % to %', OLD.job_status, NEW.job_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS validate_job_status_transition ON jobs;

-- Create the trigger
CREATE TRIGGER validate_job_status_transition
    BEFORE UPDATE OF job_status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION private.validate_job_status_transition(); 