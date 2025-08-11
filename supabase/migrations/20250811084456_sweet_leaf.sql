/*
  # Create barcodes table

  1. New Tables
    - `barcodes`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `code` (text, unique)
      - `type` (enum: table, counter, menu)
      - `identifier` (text, nullable)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `barcodes` table
    - Add policies for restaurant access
*/

-- Create barcode type enum
CREATE TYPE barcode_type AS ENUM ('table', 'counter', 'menu');

-- Create barcodes table
CREATE TABLE IF NOT EXISTS barcodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  code text UNIQUE NOT NULL,
  type barcode_type NOT NULL,
  identifier text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE barcodes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant users can manage their barcodes"
  ON barcodes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = barcodes.restaurant_id
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_barcodes_updated_at
  BEFORE UPDATE ON barcodes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_barcodes_restaurant_id ON barcodes(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_barcodes_code ON barcodes(code);
CREATE INDEX IF NOT EXISTS idx_barcodes_type ON barcodes(restaurant_id, type);