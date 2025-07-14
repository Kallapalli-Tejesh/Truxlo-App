-- First, ensure authenticated users have proper permissions
GRANT ALL ON public.profiles TO authenticated;

-- Drop existing insert policy if exists
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "enable_insert_for_authenticated" ON profiles;

-- Create a more permissive insert policy for profiles
CREATE POLICY "enable_insert_for_authenticated" ON profiles 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
        auth.uid() = id OR 
        (
            -- Allow service role to insert profiles
            auth.role() = 'service_role' OR 
            -- Allow authenticated users to insert their own profile
            (auth.role() = 'authenticated' AND auth.uid() = id)
        )
    );

-- Create a function to handle profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, is_profile_complete)
    VALUES (
        new.id,
        new.email,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'role',
        false
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions to the postgres role
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON public.profiles TO postgres;

-- Add a policy for the postgres role
CREATE POLICY "allow_postgres_all" ON public.profiles
    FOR ALL
    TO postgres
    USING (true)
    WITH CHECK (true); 