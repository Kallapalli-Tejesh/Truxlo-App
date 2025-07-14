-- Step 1: Update all references to use job_status instead of status in functions and policies

-- Update has_active_job function
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

-- Update jobs policies
DROP POLICY IF EXISTS "jobs_open_select_policy" ON jobs;
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT USING (job_status = 'open');

DROP POLICY IF EXISTS "jobs_driver_update_policy" ON jobs;
CREATE POLICY "jobs_driver_update_policy" ON jobs
    FOR UPDATE USING (
        assigned_driver_id = auth.uid() AND
        job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
    );

-- Create a view to maintain backward compatibility
CREATE OR REPLACE VIEW jobs_with_status AS
SELECT 
    *,
    job_status as status
FROM jobs;

-- Grant access to the view
GRANT SELECT ON jobs_with_status TO authenticated;

-- Add helpful comments
COMMENT ON VIEW jobs_with_status IS 'Compatibility view that exposes job_status as status for backward compatibility';
COMMENT ON COLUMN jobs.job_status IS 'Current status of the job (open, assigned, awaitingPickupVerification, inTransit, completed, cancelled)'; 