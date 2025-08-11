/*
  # Create business hours table

  1. New Tables
    - `business_hours`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `revenue_center_id` (uuid, references revenue_centers)
      - `day_of_week` (integer, 0=Sunday, 1=Monday, etc.)
      - `open_time` (time, nullable)
      - `close_time` (time, nullable)
      - `is_closed` (boolean, default false)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `business_hours` table
    - Add policies for restaurant access
*/

-- Create business hours table
CREATE TABLE IF NOT EXISTS business_hours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  revenue_center_id uuid NOT NULL REFERENCES revenue_centers(id) ON DELETE CASCADE,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  open_time time,
  close_time time,
  is_closed boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(revenue_center_id, day_of_week)
);

-- Enable RLS
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant users can manage their business hours"
  ON business_hours
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = business_hours.restaurant_id
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_business_hours_updated_at
  BEFORE UPDATE ON business_hours
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_business_hours_restaurant_id ON business_hours(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_business_hours_revenue_center ON business_hours(revenue_center_id);
CREATE INDEX IF NOT EXISTS idx_business_hours_day ON business_hours(revenue_center_id, day_of_week);