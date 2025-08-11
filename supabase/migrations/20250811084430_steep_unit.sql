/*
  # Create order-related tables

  1. New Tables
    - `orders`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `customer_id` (uuid, references customers, nullable)
      - `order_number` (text, unique)
      - `type` (enum: dine_in, takeaway, delivery)
      - `status` (enum: pending, preparing, ready, served, cancelled)
      - `table_number` (text, nullable)
      - `delivery_location` (text, nullable)
      - `subtotal` (decimal)
      - `tax_amount` (decimal)
      - `discount_amount` (decimal, default 0.00)
      - `total_amount` (decimal)
      - `notes` (text, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `order_items`
      - `id` (uuid, primary key)
      - `order_id` (uuid, references orders)
      - `menu_item_id` (uuid, references menu_items, nullable)
      - `combo_meal_id` (uuid, references combo_meals, nullable)
      - `revenue_center_id` (uuid, references revenue_centers)
      - `quantity` (integer)
      - `unit_price` (decimal)
      - `total_price` (decimal)
      - `customizations` (jsonb, default '{}')
      - `special_instructions` (text, nullable)
      - `status` (enum: pending, preparing, ready, served)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on order tables
    - Add policies for restaurant access
*/

-- Create order type enum
CREATE TYPE order_type AS ENUM ('dine_in', 'takeaway', 'delivery');

-- Create order status enum
CREATE TYPE order_status AS ENUM ('pending', 'preparing', 'ready', 'served', 'cancelled');

-- Create order item status enum
CREATE TYPE order_item_status AS ENUM ('pending', 'preparing', 'ready', 'served');

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  order_number text UNIQUE NOT NULL,
  type order_type NOT NULL,
  status order_status DEFAULT 'pending',
  table_number text,
  delivery_location text,
  subtotal decimal(10,2) NOT NULL,
  tax_amount decimal(10,2) NOT NULL DEFAULT 0.00,
  discount_amount decimal(10,2) DEFAULT 0.00,
  total_amount decimal(10,2) NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create order items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id uuid REFERENCES menu_items(id) ON DELETE SET NULL,
  combo_meal_id uuid REFERENCES combo_meals(id) ON DELETE SET NULL,
  revenue_center_id uuid NOT NULL REFERENCES revenue_centers(id) ON DELETE CASCADE,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price decimal(10,2) NOT NULL,
  total_price decimal(10,2) NOT NULL,
  customizations jsonb DEFAULT '{}',
  special_instructions text,
  status order_item_status DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT check_item_reference CHECK (
    (menu_item_id IS NOT NULL AND combo_meal_id IS NULL) OR
    (menu_item_id IS NULL AND combo_meal_id IS NOT NULL)
  )
);

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Create policies for orders
CREATE POLICY "Restaurant users can manage their orders"
  ON orders
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = orders.restaurant_id
    )
  );

-- Create policies for order_items
CREATE POLICY "Restaurant users can manage their order items"
  ON order_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      JOIN users u ON u.auth_user_id = auth.uid()
      WHERE o.id = order_items.order_id
      AND u.restaurant_id = o.restaurant_id
    )
  );

-- Create updated_at triggers
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_order_items_updated_at
  BEFORE UPDATE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(restaurant_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(restaurant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_revenue_center ON order_items(revenue_center_id);