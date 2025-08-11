/*
  # Create revenue centers table

  1. New Tables
    - `revenue_centers`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `name` (text)
      - `type` (enum: restaurant, bar, patio, takeout)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `revenue_centers` table
    - Add policies for restaurant access
*/

-- Create revenue center type enum
CREATE TYPE revenue_center_type AS ENUM ('restaurant', 'bar', 'patio', 'takeout');

-- Create revenue centers table
CREATE TABLE IF NOT EXISTS revenue_centers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name text NOT NULL,
  type revenue_center_type NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE revenue_centers ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant users can manage their revenue centers"
  ON revenue_centers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = revenue_centers.restaurant_id
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_revenue_centers_updated_at
  BEFORE UPDATE ON revenue_centers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();