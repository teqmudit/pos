/*
  # Create payments table

  1. New Tables
    - `payments`
      - `id` (uuid, primary key)
      - `order_id` (uuid, references orders)
      - `amount` (decimal)
      - `method` (enum: cash, card, gift_card, online)
      - `status` (enum: pending, completed, failed, refunded)
      - `transaction_id` (text, nullable)
      - `processed_at` (timestamptz, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `payments` table
    - Add policies for restaurant access
*/

-- Create payment method enum
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'gift_card', 'online');

-- Create payment status enum
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  amount decimal(10,2) NOT NULL,
  method payment_method NOT NULL,
  status payment_status DEFAULT 'pending',
  transaction_id text,
  processed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Restaurant users can manage their payments"
  ON payments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      JOIN users u ON u.auth_user_id = auth.uid()
      WHERE o.id = payments.order_id
      AND u.restaurant_id = o.restaurant_id
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(method);