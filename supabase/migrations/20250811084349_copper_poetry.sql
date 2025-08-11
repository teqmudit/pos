/*
  # Create users table

  1. New Tables
    - `users`
      - `id` (uuid, primary key)
      - `auth_user_id` (uuid, references auth.users)
      - `email` (text, unique)
      - `full_name` (text)
      - `role` (enum: super_admin, kitchen_owner, manager, staff)
      - `restaurant_id` (uuid, nullable)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `users` table
    - Add policies for different user roles
*/

-- Create user role enum
CREATE TYPE user_role_type AS ENUM ('super_admin', 'kitchen_owner', 'manager', 'staff');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role user_role_type NOT NULL,
  restaurant_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

CREATE POLICY "Super admins can manage all users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners and managers can manage restaurant staff"
  ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.restaurant_id = users.restaurant_id
      AND u.role IN ('kitchen_owner', 'manager')
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();