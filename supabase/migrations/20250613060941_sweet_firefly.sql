/*
  # Kitchen POS Admin Panel Database Schema

  1. New Tables
    - `users` - System users (super admin, kitchen owners, managers, staff)
    - `kitchen_owners` - Kitchen owner subscription details
    - `restaurants` - Restaurant/kitchen information
    - `revenue_centers` - Bar, Restaurant, etc.
    - `staff_assignments` - Staff to revenue center assignments
    - `menu_categories` - Menu categories
    - `menu_items` - Menu items
    - `combo_meals` - Combo meal definitions
    - `daily_deals` - Daily special offers
    - `barcodes` - QR codes for tables and counters
    - `orders` - Customer orders
    - `order_items` - Individual items in orders
    - `payments` - Payment records
    - `customers` - Customer information
    - `business_hours` - Restaurant/bar operating hours

  2. Security
    - Enable RLS on all tables
    - Add policies for role-based access control
    - Multi-tenant isolation for kitchen owners
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE user_role AS ENUM ('super_admin', 'kitchen_owner', 'manager', 'staff');
CREATE TYPE subscription_plan AS ENUM ('basic', 'premium', 'enterprise');
CREATE TYPE restaurant_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE order_status AS ENUM ('pending', 'preparing', 'ready', 'served', 'cancelled');
CREATE TYPE order_type AS ENUM ('dine_in', 'takeaway', 'delivery');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'gift_card', 'online');
CREATE TYPE revenue_center_type AS ENUM ('restaurant', 'bar', 'patio', 'takeout');

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role user_role NOT NULL DEFAULT 'staff',
  restaurant_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Kitchen owners subscription table
CREATE TABLE IF NOT EXISTS kitchen_owners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  subscription_plan subscription_plan NOT NULL,
  payment_id text NOT NULL,
  subscription_amount decimal(10,2) NOT NULL,
  subscription_expires_at timestamptz NOT NULL,
  password_hash text NOT NULL,
  is_setup_completed boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Restaurants table
CREATE TABLE IF NOT EXISTS restaurants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES kitchen_owners(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text NOT NULL,
  phone_number text NOT NULL,
  domain_name text UNIQUE NOT NULL,
  status restaurant_status DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Revenue centers (Bar, Restaurant, etc.)
CREATE TABLE IF NOT EXISTS revenue_centers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  name text NOT NULL,
  type revenue_center_type NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Staff assignments to revenue centers
CREATE TABLE IF NOT EXISTS staff_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  revenue_center_id uuid REFERENCES revenue_centers(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, revenue_center_id)
);

-- Menu categories
CREATE TABLE IF NOT EXISTS menu_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  revenue_center_id uuid REFERENCES revenue_centers(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Menu items
CREATE TABLE IF NOT EXISTS menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  category_id uuid REFERENCES menu_categories(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  image_url text,
  is_available boolean DEFAULT true,
  customizable_options jsonb DEFAULT '[]',
  allergen_info text,
  preparation_time integer DEFAULT 15,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Combo meals
CREATE TABLE IF NOT EXISTS combo_meals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  image_url text,
  items jsonb NOT NULL DEFAULT '[]', -- Array of menu item IDs and quantities
  is_available boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Daily deals
CREATE TABLE IF NOT EXISTS daily_deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  discount_percentage decimal(5,2),
  discount_amount decimal(10,2),
  applicable_items jsonb DEFAULT '[]', -- Array of menu item IDs
  valid_from timestamptz NOT NULL,
  valid_until timestamptz NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Barcodes for tables and counters
CREATE TABLE IF NOT EXISTS barcodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  code text UNIQUE NOT NULL,
  type text NOT NULL, -- 'table', 'counter', 'menu'
  identifier text, -- table number, counter name, etc.
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  name text,
  email text,
  phone text,
  total_orders integer DEFAULT 0,
  total_spent decimal(10,2) DEFAULT 0,
  last_order_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id),
  order_number text UNIQUE NOT NULL,
  type order_type NOT NULL,
  status order_status DEFAULT 'pending',
  table_number text,
  delivery_location text, -- Golf course hole number, etc.
  subtotal decimal(10,2) NOT NULL DEFAULT 0,
  tax_amount decimal(10,2) NOT NULL DEFAULT 0,
  discount_amount decimal(10,2) NOT NULL DEFAULT 0,
  total_amount decimal(10,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Order items
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id uuid REFERENCES menu_items(id),
  combo_meal_id uuid REFERENCES combo_meals(id),
  revenue_center_id uuid REFERENCES revenue_centers(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1,
  unit_price decimal(10,2) NOT NULL,
  total_price decimal(10,2) NOT NULL,
  customizations jsonb DEFAULT '{}',
  special_instructions text,
  status order_status DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT order_items_item_check CHECK (
    (menu_item_id IS NOT NULL AND combo_meal_id IS NULL) OR
    (menu_item_id IS NULL AND combo_meal_id IS NOT NULL)
  )
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  amount decimal(10,2) NOT NULL,
  method payment_method NOT NULL,
  status payment_status DEFAULT 'pending',
  transaction_id text,
  processed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Business hours
CREATE TABLE IF NOT EXISTS business_hours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
  revenue_center_id uuid REFERENCES revenue_centers(id) ON DELETE CASCADE,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0 = Sunday
  open_time time,
  close_time time,
  is_closed boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(restaurant_id, revenue_center_id, day_of_week)
);

-- Add foreign key constraint for restaurant_id in users table
ALTER TABLE users ADD CONSTRAINT users_restaurant_id_fkey 
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE SET NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_restaurant_id ON users(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_kitchen_owners_email ON kitchen_owners(email);
CREATE INDEX IF NOT EXISTS idx_restaurants_owner_id ON restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_domain_name ON restaurants(domain_name);
CREATE INDEX IF NOT EXISTS idx_revenue_centers_restaurant_id ON revenue_centers(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category_id ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_revenue_center_id ON order_items(revenue_center_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_customers_restaurant_id ON customers(restaurant_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Users policies
CREATE POLICY "Super admin can manage all users"
  ON users FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can manage their restaurant users"
  ON users FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT r.id FROM restaurants r
      JOIN kitchen_owners ko ON ko.id = r.owner_id
      JOIN users u ON u.id = ko.user_id
      WHERE u.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can read their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Kitchen owners policies
CREATE POLICY "Super admin can manage all kitchen owners"
  ON kitchen_owners FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can read their own data"
  ON kitchen_owners FOR SELECT
  TO authenticated
  USING (
    user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  );

-- Restaurants policies
CREATE POLICY "Super admin can manage all restaurants"
  ON restaurants FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

CREATE POLICY "Kitchen owners can manage their restaurants"
  ON restaurants FOR ALL
  TO authenticated
  USING (
    owner_id IN (
      SELECT ko.id FROM kitchen_owners ko
      JOIN users u ON u.id = ko.user_id
      WHERE u.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Restaurant staff can read their restaurant"
  ON restaurants FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    )
  );

-- Revenue centers policies
CREATE POLICY "Restaurant users can manage their revenue centers"
  ON revenue_centers FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Staff assignments policies
CREATE POLICY "Restaurant users can manage staff assignments"
  ON staff_assignments FOR ALL
  TO authenticated
  USING (
    revenue_center_id IN (
      SELECT rc.id FROM revenue_centers rc
      JOIN users u ON u.restaurant_id = rc.restaurant_id
      WHERE u.auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Menu categories policies
CREATE POLICY "Restaurant users can manage their menu categories"
  ON menu_categories FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Menu items policies
CREATE POLICY "Restaurant users can manage their menu items"
  ON menu_items FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Combo meals policies
CREATE POLICY "Restaurant users can manage their combo meals"
  ON combo_meals FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Daily deals policies
CREATE POLICY "Restaurant users can manage their daily deals"
  ON daily_deals FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Barcodes policies
CREATE POLICY "Restaurant users can manage their barcodes"
  ON barcodes FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Customers policies
CREATE POLICY "Restaurant users can manage their customers"
  ON customers FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Orders policies
CREATE POLICY "Restaurant users can manage their orders"
  ON orders FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Order items policies
CREATE POLICY "Restaurant users can manage their order items"
  ON order_items FOR ALL
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM orders o
      JOIN users u ON u.restaurant_id = o.restaurant_id
      WHERE u.auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Payments policies
CREATE POLICY "Restaurant users can manage their payments"
  ON payments FOR ALL
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM orders o
      JOIN users u ON u.restaurant_id = o.restaurant_id
      WHERE u.auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Business hours policies
CREATE POLICY "Restaurant users can manage their business hours"
  ON business_hours FOR ALL
  TO authenticated
  USING (
    restaurant_id IN (
      SELECT restaurant_id FROM users WHERE auth_user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.auth_user_id = auth.uid() AND u.role = 'super_admin'
    )
  );

-- Insert super admin user
INSERT INTO users (
  email,
  full_name,
  role,
  is_active
) VALUES (
  'pdeep@teqmavens.com',
  'Super Admin',
  'super_admin',
  true
) ON CONFLICT (email) DO NOTHING;