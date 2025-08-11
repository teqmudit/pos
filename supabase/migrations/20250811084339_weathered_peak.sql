/*
  # Create kitchen owners table

  1. New Tables
    - `kitchen_owners`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `email` (text, unique)
      - `full_name` (text)
      - `subscription_plan` (enum: basic, premium, enterprise)
      - `payment_id` (text)
      - `subscription_amount` (decimal)
      - `subscription_expires_at` (timestamptz)
      - `password_hash` (text)
      - `is_setup_completed` (boolean, default false)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `kitchen_owners` table
    - Add policy for super admins to manage all kitchen owners
    - Add policy for kitchen owners to read their own data
*/

-- Create subscription plan enum
CREATE TYPE subscription_plan_type AS ENUM ('basic', 'premium', 'enterprise');

-- Create kitchen owners table
CREATE TABLE IF NOT EXISTS kitchen_owners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  subscription_plan subscription_plan_type NOT NULL DEFAULT 'basic',
  payment_id text NOT NULL,
  subscription_amount decimal(10,2) NOT NULL DEFAULT 0.00,
  subscription_expires_at timestamptz NOT NULL,
  password_hash text NOT NULL,
  is_setup_completed boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE kitchen_owners ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Super admins can manage all kitchen owners"
  ON kitchen_owners
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can read their own data"
  ON kitchen_owners
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_kitchen_owners_updated_at
  BEFORE UPDATE ON kitchen_owners
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();