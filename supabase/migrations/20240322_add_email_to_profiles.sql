-- Add email column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Create function to get user email from auth.users
CREATE OR REPLACE FUNCTION get_user_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Get email from auth.users and set it in profiles
    NEW.email := (
        SELECT email 
        FROM auth.users 
        WHERE id = NEW.id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically set email on insert/update
CREATE OR REPLACE TRIGGER set_user_email
    BEFORE INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION get_user_email();

-- Update existing profiles with emails
UPDATE profiles
SET email = (
    SELECT email 
    FROM auth.users 
    WHERE users.id = profiles.id
);

-- Add comment to explain the trigger
COMMENT ON TRIGGER set_user_email ON profiles IS 'Automatically sets email from auth.users when a profile is created or updated'; 