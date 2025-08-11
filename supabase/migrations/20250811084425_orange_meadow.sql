/*
  # Create customers table

  1. New Tables
    - `customers`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `name` (text, nullable)
      - `email` (text, nullable)
      - `phone` (text, nullable)
      - `total_orders` (integer, default 0)
      - `total_spent` (decimal, default 0.00)
      - `last_order_at` (timestamptz, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `customers` table
    - Add policies for restaurant access
*/

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name text,
  email text,
  phone text,
  total_orders integer DEFAULT 0,
  total_spent decimal(10,2) DEFAULT 0.00,
  last_order_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant users can manage their customers"
  ON customers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = customers.restaurant_id
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_restaurant_id ON customers(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(restaurant_id, email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(restaurant_id, phone) WHERE phone IS NOT NULL;