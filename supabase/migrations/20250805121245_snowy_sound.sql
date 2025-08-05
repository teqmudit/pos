/*
  # Create Golf Courses and Kitchen-Golf Course Relationships

  1. New Tables
    - `golf_courses`
      - `id` (uuid, primary key)
      - `name` (text)
      - `address` (text)
      - `phone_number` (text)
      - `email` (text)
      - `website` (text, optional)
      - `is_active` (boolean, default true)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `kitchen_golf_course_assignments`
      - `id` (uuid, primary key)
      - `kitchen_id` (uuid, references restaurants)
      - `golf_course_id` (uuid, references golf_courses)
      - `is_active` (boolean, default true)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for kitchen owners to manage their assignments
    - Add policies for super admin to manage all data

  3. Indexes
    - Add indexes for foreign keys and common queries
    - Add unique constraint on kitchen-golf course combination
*/

-- Create golf_courses table
CREATE TABLE IF NOT EXISTS golf_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text NOT NULL,
  phone_number text,
  email text,
  website text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create kitchen_golf_course_assignments table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS kitchen_golf_course_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  golf_course_id uuid NOT NULL REFERENCES golf_courses(id) ON DELETE CASCADE,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(kitchen_id, golf_course_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_golf_courses_name ON golf_courses(name);
CREATE INDEX IF NOT EXISTS idx_golf_courses_is_active ON golf_courses(is_active);
CREATE INDEX IF NOT EXISTS idx_kitchen_golf_assignments_kitchen_id ON kitchen_golf_course_assignments(kitchen_id);
CREATE INDEX IF NOT EXISTS idx_kitchen_golf_assignments_golf_course_id ON kitchen_golf_course_assignments(golf_course_id);
CREATE INDEX IF NOT EXISTS idx_kitchen_golf_assignments_active ON kitchen_golf_course_assignments(is_active);

-- Enable RLS
ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_golf_course_assignments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for golf_courses
CREATE POLICY "Super admin can manage all golf courses"
  ON golf_courses
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() 
      AND u.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can read golf courses"
  ON golf_courses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() 
      AND u.role IN ('kitchen_owner', 'manager', 'staff')
    )
  );

-- RLS Policies for kitchen_golf_course_assignments
CREATE POLICY "Super admin can manage all assignments"
  ON kitchen_golf_course_assignments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() 
      AND u.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can manage their assignments"
  ON kitchen_golf_course_assignments
  FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT r.id 
      FROM restaurants r
      JOIN kitchen_owners ko ON ko.id = r.owner_id
      JOIN users u ON u.id = ko.user_id
      WHERE u.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Restaurant staff can read their assignments"
  ON kitchen_golf_course_assignments
  FOR SELECT
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT u.restaurant_id 
      FROM users u 
      WHERE u.auth_user_id = auth.uid()
    )
  );

-- Add some sample golf courses
INSERT INTO golf_courses (name, address, phone_number, email, website) VALUES
  ('Sunrise Golf Club', '123 Golf Course Rd, Mumbai, Maharashtra 400001', '+91-22-1234-5678', 'info@sunrisegolf.com', 'https://sunrisegolf.com'),
  ('Royal Greens Golf Course', '456 Fairway Ave, Delhi, Delhi 110001', '+91-11-2345-6789', 'contact@royalgreens.com', 'https://royalgreens.com'),
  ('Ocean View Golf Resort', '789 Coastal Hwy, Goa, Goa 403001', '+91-832-345-6789', 'reservations@oceanviewgolf.com', 'https://oceanviewgolf.com'),
  ('Mountain Peak Golf Club', '321 Highland Dr, Shimla, Himachal Pradesh 171001', '+91-177-456-7890', 'info@mountainpeakgolf.com', 'https://mountainpeakgolf.com'),
  ('City Center Golf Course', '654 Urban Plaza, Bangalore, Karnataka 560001', '+91-80-567-8901', 'admin@citycentergolf.com', 'https://citycentergolf.com')
ON CONFLICT DO NOTHING;