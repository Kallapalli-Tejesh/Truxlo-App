-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('driver', 'warehouse_owner', 'broker')),
  address TEXT,
  city TEXT,
  state TEXT,
  is_profile_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create driver details table
CREATE TABLE IF NOT EXISTS driver_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  license_number TEXT,
  license_expiry DATE,
  vehicle_type TEXT,
  experience_years INTEGER,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id)
);

-- Create warehouse details table
CREATE TABLE IF NOT EXISTS warehouse_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  warehouse_name TEXT,
  storage_capacity DECIMAL,
  operating_hours TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id)
);

-- Create broker details table
CREATE TABLE IF NOT EXISTS broker_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  company_name TEXT,
  registration_number TEXT,
  years_in_business INTEGER,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id)
);

-- Create broker-driver relationship table
CREATE TABLE IF NOT EXISTS broker_drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  broker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'active', 'rejected', 'removed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(broker_id, driver_id)
);

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  warehouse_owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  goods_type TEXT NOT NULL,
  weight DECIMAL NOT NULL,
  price DECIMAL NOT NULL,
  pickup_location TEXT NOT NULL,
  destination TEXT NOT NULL,
  distance DECIMAL NOT NULL,
  posted_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  status TEXT CHECK (status IN ('open', 'assigned', 'in_progress', 'completed', 'cancelled')) DEFAULT 'open',
  assigned_driver_id UUID REFERENCES profiles(id),
  assigned_date TIMESTAMP WITH TIME ZONE,
  completion_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create job applications table
CREATE TABLE IF NOT EXISTS job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'accepted', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(job_id, driver_id)
);

-- Create RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE broker_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE broker_drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Driver details policies
CREATE POLICY "Users can view their own driver details"
  ON driver_details FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own driver details"
  ON driver_details FOR UPDATE
  USING (auth.uid() = user_id);

-- Warehouse details policies
CREATE POLICY "Users can view their own warehouse details"
  ON warehouse_details FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own warehouse details"
  ON warehouse_details FOR UPDATE
  USING (auth.uid() = user_id);

-- Broker details policies
CREATE POLICY "Users can view their own broker details"
  ON broker_details FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own broker details"
  ON broker_details FOR UPDATE
  USING (auth.uid() = user_id);

-- Broker-driver relationship policies
CREATE POLICY "Brokers can view their driver relationships"
  ON broker_drivers FOR SELECT
  USING (auth.uid() = broker_id);

CREATE POLICY "Drivers can view their broker relationships"
  ON broker_drivers FOR SELECT
  USING (auth.uid() = driver_id);

CREATE POLICY "Brokers can create driver relationships"
  ON broker_drivers FOR INSERT
  WITH CHECK (auth.uid() = broker_id);

CREATE POLICY "Brokers can update their driver relationships"
  ON broker_drivers FOR UPDATE
  USING (auth.uid() = broker_id);

-- Jobs policies
CREATE POLICY "Warehouse owners can view their own jobs"
  ON jobs FOR SELECT
  USING (auth.uid() = warehouse_owner_id);

CREATE POLICY "Warehouse owners can create jobs"
  ON jobs FOR INSERT
  WITH CHECK (auth.uid() = warehouse_owner_id);

CREATE POLICY "Warehouse owners can update their own jobs"
  ON jobs FOR UPDATE
  USING (auth.uid() = warehouse_owner_id);

CREATE POLICY "Drivers can view all open jobs"
  ON jobs FOR SELECT
  USING (status = 'open' OR assigned_driver_id = auth.uid());

-- Job applications policies
CREATE POLICY "Drivers can view their own applications"
  ON job_applications FOR SELECT
  USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can create applications"
  ON job_applications FOR INSERT
  WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Warehouse owners can view applications for their jobs"
  ON job_applications FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = job_applications.job_id
    AND jobs.warehouse_owner_id = auth.uid()
  ));

CREATE POLICY "Warehouse owners can update applications for their jobs"
  ON job_applications FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = job_applications.job_id
    AND jobs.warehouse_owner_id = auth.uid()
  ));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_driver_details_user_id ON driver_details(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_details_user_id ON warehouse_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_details_user_id ON broker_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_broker_id ON broker_drivers(broker_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_driver_id ON broker_drivers(driver_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_status ON broker_drivers(status);
CREATE INDEX IF NOT EXISTS idx_jobs_warehouse_owner_id ON jobs(warehouse_owner_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_driver_id ON jobs(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_job_id ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_driver_id ON job_applications(driver_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(status);

-- Add composite indexes for frequently used queries
CREATE INDEX IF NOT EXISTS idx_job_applications_job_status ON job_applications(job_id, status);
CREATE INDEX IF NOT EXISTS idx_job_applications_driver_status ON job_applications(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_owner_status ON jobs(warehouse_owner_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_driver_status ON jobs(assigned_driver_id, status); 