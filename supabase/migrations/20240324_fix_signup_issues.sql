-- Step 1: Drop existing policies and triggers
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
DROP POLICY IF EXISTS "enable_insert_for_authenticated" ON public.profiles;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 2: Temporarily modify profiles table constraints
ALTER TABLE public.profiles ALTER COLUMN phone DROP NOT NULL;

-- Step 3: Create or replace the handle_new_user function with proper error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert with proper error handling and all required fields
    BEGIN
        INSERT INTO public.profiles (
            id,
            email,
            full_name,
            phone,
            role,
            is_profile_complete,
            created_at,
            updated_at
        )
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'phone', ''),
            COALESCE(NEW.raw_user_meta_data->>'role', 'driver'),
            false,
            now(),
            now()
        );
    EXCEPTION WHEN OTHERS THEN
        -- Log error details
        RAISE NOTICE 'Error creating profile: %', SQLERRM;
        -- Continue with trigger execution even if profile creation fails
        -- This prevents blocking user creation
        RETURN NEW;
    END;
    
    RETURN NEW;
END;
$$;

-- Step 4: Create new trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Create new policies with proper permissions

-- Allow service role full access
CREATE POLICY "service_role_policy" ON public.profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Insert policy for authenticated users
CREATE POLICY "profiles_insert_policy" ON public.profiles 
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- Select policy with optimized query
CREATE POLICY "profiles_select_policy" ON public.profiles 
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

-- Update policy
CREATE POLICY "profiles_update_policy" ON public.profiles 
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Step 6: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, authenticated, service_role;

-- Step 7: Create or update necessary indexes
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_id ON public.profiles(id) WHERE id = auth.uid();

-- Step 8: Add helpful comments
COMMENT ON FUNCTION public.handle_new_user IS 'Automatically creates a profile when a new user signs up';
COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 'Trigger to handle new user profile creation';
COMMENT ON POLICY "service_role_policy" ON public.profiles IS 'Allows service role full access to profiles';
COMMENT ON POLICY "profiles_insert_policy" ON public.profiles IS 'Allows users to create their own profile';
COMMENT ON POLICY "profiles_select_policy" ON public.profiles IS 'Allows users to view their own profile and related profiles';
COMMENT ON POLICY "profiles_update_policy" ON public.profiles IS 'Allows users to update their own profile'; 