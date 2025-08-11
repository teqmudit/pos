/*
  # Create restaurants table

  1. New Tables
    - `restaurants`
      - `id` (uuid, primary key)
      - `owner_id` (uuid, references kitchen_owners)
      - `name` (text)
      - `address` (text)
      - `phone_number` (text)
      - `domain_name` (text, unique)
      - `status` (enum: active, inactive, suspended)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `restaurants` table
    - Add policies for different access levels
*/

-- Create restaurant status enum
CREATE TYPE restaurant_status_type AS ENUM ('active', 'inactive', 'suspended');

-- Create restaurants table
CREATE TABLE IF NOT EXISTS restaurants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES kitchen_owners(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text NOT NULL,
  phone_number text NOT NULL,
  domain_name text UNIQUE NOT NULL,
  status restaurant_status_type DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Super admins can manage all restaurants"
  ON restaurants
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can manage their restaurants"
  ON restaurants
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM kitchen_owners ko
      JOIN users u ON u.auth_user_id = auth.uid()
      WHERE ko.id = restaurants.owner_id
      AND ko.user_id = u.auth_user_id
    )
  );

CREATE POLICY "Restaurant staff can read their restaurant"
  ON restaurants
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = restaurants.id
    )
  );

-- Add foreign key constraint to users table
ALTER TABLE users 
ADD CONSTRAINT fk_users_restaurant 
FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE SET NULL;

-- Create updated_at trigger
CREATE TRIGGER update_restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();