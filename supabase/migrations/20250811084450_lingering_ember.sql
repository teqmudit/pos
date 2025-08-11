/*
  # Create staff-related tables

  1. New Tables
    - `staff_assignments`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references users)
      - `revenue_center_id` (uuid, references revenue_centers)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on staff tables
    - Add policies for restaurant access
*/

-- Create staff assignments table
CREATE TABLE IF NOT EXISTS staff_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  revenue_center_id uuid NOT NULL REFERENCES revenue_centers(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, revenue_center_id)
);

-- Enable RLS
ALTER TABLE staff_assignments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant managers can manage staff assignments"
  ON staff_assignments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN revenue_centers rc ON rc.id = staff_assignments.revenue_center_id
      WHERE u.auth_user_id = auth.uid()
      AND u.restaurant_id = rc.restaurant_id
      AND u.role IN ('kitchen_owner', 'manager')
    )
  );

CREATE POLICY "Staff can read their own assignments"
  ON staff_assignments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.id = staff_assignments.user_id
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_staff_assignments_user_id ON staff_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_assignments_revenue_center ON staff_assignments(revenue_center_id);