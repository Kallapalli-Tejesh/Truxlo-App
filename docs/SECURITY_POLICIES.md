# Database Security Policies Documentation

## Overview
This document details the Row Level Security (RLS) policies for all tables in the system. These policies ensure proper data access control and maintain security across the application.

## Enable RLS on All Tables
```sql
-- Enable RLS on main tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Enable RLS on role-specific tables
ALTER TABLE public.driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_details ENABLE ROW LEVEL SECURITY;
```

## Profiles Table Policies

### Read Access
```sql
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT
    USING (
        id = auth.uid() OR  -- User can read their own profile
        id IN (             -- Or profiles they interact with through jobs
            SELECT assigned_driver_id FROM jobs WHERE warehouse_owner_id = auth.uid()
            UNION
            SELECT warehouse_owner_id FROM jobs WHERE assigned_driver_id = auth.uid()
        )
    );
```

### Update Access
```sql
CREATE POLICY "profiles_update_policy" ON profiles
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());
```

### Insert Access
```sql
CREATE POLICY "profiles_insert_policy" ON profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());
```

## Driver Details Table Policies

### Read Access
```sql
CREATE POLICY "driver_details_select_policy" ON driver_details
    FOR SELECT
    USING (
        user_id = auth.uid() OR  -- Driver can read own details
        user_id IN (             -- Warehouse owners can read their drivers' details
            SELECT assigned_driver_id 
            FROM jobs 
            WHERE warehouse_owner_id = auth.uid()
        )
    );
```

### Update Access
```sql
CREATE POLICY "driver_details_update_policy" ON driver_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
```

### Insert Access
```sql
CREATE POLICY "driver_details_insert_policy" ON driver_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
```

## Warehouse Details Table Policies

### Read Access
```sql
CREATE POLICY "warehouse_details_select_policy" ON warehouse_details
    FOR SELECT
    USING (
        user_id = auth.uid() OR  -- Warehouse owner can read own details
        user_id IN (             -- Drivers can read warehouse details of their jobs
            SELECT warehouse_owner_id 
            FROM jobs 
            WHERE assigned_driver_id = auth.uid()
        )
    );
```

### Update Access
```sql
CREATE POLICY "warehouse_details_update_policy" ON warehouse_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
```

### Insert Access
```sql
CREATE POLICY "warehouse_details_insert_policy" ON warehouse_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
```

## Broker Details Table Policies

### Read Access
```sql
CREATE POLICY "broker_details_select_policy" ON broker_details
    FOR SELECT
    USING (user_id = auth.uid());
```

### Update Access
```sql
CREATE POLICY "broker_details_update_policy" ON broker_details
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
```

### Insert Access
```sql
CREATE POLICY "broker_details_insert_policy" ON broker_details
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
```

## Jobs Table Policies

### Read Access
```sql
-- Anyone can read open jobs
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    USING (status = 'open');

-- Users can read their own jobs
CREATE POLICY "jobs_own_select_policy" ON jobs
    FOR SELECT
    USING (
        warehouse_owner_id = auth.uid() OR
        assigned_driver_id = auth.uid()
    );
```

### Insert Access
```sql
-- Only warehouse owners can create jobs
CREATE POLICY "jobs_insert_policy" ON jobs
    FOR INSERT
    WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'warehouse_owner'
        )
    );
```

### Update Access
```sql
-- Warehouse owners can update their jobs
CREATE POLICY "jobs_owner_update_policy" ON jobs
    FOR UPDATE
    USING (warehouse_owner_id = auth.uid());

-- Assigned drivers can update job status
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
```

## Job Applications Table Policies

### Read Access
```sql
CREATE POLICY "applications_select_policy" ON job_applications
    FOR SELECT
    USING (
        driver_id = auth.uid() OR  -- Driver can read own applications
        job_id IN (                -- Warehouse owner can read applications for their jobs
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );
```

### Insert Access
```sql
-- Only drivers can create applications
CREATE POLICY "applications_insert_policy" ON job_applications
    FOR INSERT
    WITH CHECK (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'driver'
        )
    );
```

### Update Access
```sql
-- Drivers can update their own applications
CREATE POLICY "applications_driver_update_policy" ON job_applications
    FOR UPDATE
    USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());

-- Warehouse owners can update applications for their jobs
CREATE POLICY "applications_owner_update_policy" ON job_applications
    FOR UPDATE
    USING (
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );
```

## Delete Policies
By default, delete operations are not allowed. If needed, specific delete policies can be added:

```sql
-- Example: Allow users to delete their own applications
CREATE POLICY "applications_delete_policy" ON job_applications
    FOR DELETE
    USING (
        driver_id = auth.uid() AND
        status = 'pending'  -- Only pending applications can be deleted
    );
```

## Best Practices

1. Policy Naming
   - Use descriptive names: `table_action_policy`
   - Include the operation type: select, insert, update, delete
   - Make the purpose clear in the name

2. Security Considerations
   - Always use `auth.uid()` for user identification
   - Avoid using `TRUE` in USING or WITH CHECK clauses
   - Include role checks where necessary
   - Use EXISTS clauses to validate relationships

3. Performance
   - Keep policies simple when possible
   - Use indexes on frequently queried columns
   - Avoid complex joins in policy definitions

4. Maintenance
   - Document all policies
   - Test policies thoroughly
   - Review and update policies when schema changes

## Testing Guidelines

1. Basic Access Tests
```sql
-- Test profile access
SELECT * FROM profiles WHERE id = 'test-user-id';
-- Should only return the user's own profile

-- Test job access
SELECT * FROM jobs WHERE status = 'open';
-- Should return all open jobs
```

2. Role-Based Tests
```sql
-- Test warehouse owner job creation
INSERT INTO jobs (warehouse_owner_id, title) VALUES ('non-owner-id', 'Test Job');
-- Should fail for non-warehouse owners

-- Test driver application creation
INSERT INTO job_applications (driver_id, job_id) VALUES ('non-driver-id', 'job-id');
-- Should fail for non-drivers
```

3. Update Permission Tests
```sql
-- Test job status update
UPDATE jobs SET status = 'completed' WHERE id = 'job-id';
-- Should only succeed for assigned driver or warehouse owner
``` 