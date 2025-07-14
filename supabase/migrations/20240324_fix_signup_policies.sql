-- Drop existing policies
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "enable_insert_for_authenticated" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create a more permissive insert policy for profiles
CREATE POLICY "profiles_insert_policy" ON profiles 
    FOR INSERT 
    WITH CHECK (
        -- Allow users to create their own profile during signup
        auth.uid() = id OR 
        -- Allow service role to create profiles
        auth.role() = 'service_role'
    );

-- Create a select policy for profiles
CREATE POLICY "profiles_select_policy" ON profiles 
    FOR SELECT 
    USING (
        -- Users can see their own profile
        auth.uid() = id OR
        -- Users can see profiles they have a job relationship with
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE 
                (warehouse_owner_id = auth.uid() AND assigned_driver_id = profiles.id)
                OR 
                (assigned_driver_id = auth.uid() AND warehouse_owner_id = profiles.id)
        )
    );

-- Create an update policy for profiles
CREATE POLICY "profiles_update_policy" ON profiles 
    FOR UPDATE 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Grant necessary permissions
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON profiles TO service_role;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id); 