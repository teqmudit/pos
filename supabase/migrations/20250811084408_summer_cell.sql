/*
  # Create menu-related tables

  1. New Tables
    - `menu_categories`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `revenue_center_id` (uuid, references revenue_centers)
      - `name` (text)
      - `description` (text, nullable)
      - `is_active` (boolean, default true)
      - `sort_order` (integer, default 0)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `menu_items`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `category_id` (uuid, references menu_categories)
      - `name` (text)
      - `description` (text, nullable)
      - `price` (decimal)
      - `image_url` (text, nullable)
      - `is_available` (boolean, default true)
      - `customizable_options` (jsonb, default '[]')
      - `allergen_info` (text, nullable)
      - `preparation_time` (integer, default 15)
      - `sort_order` (integer, default 0)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `combo_meals`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `name` (text)
      - `description` (text, nullable)
      - `price` (decimal)
      - `image_url` (text, nullable)
      - `items` (jsonb, default '[]')
      - `is_available` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `daily_deals`
      - `id` (uuid, primary key)
      - `restaurant_id` (uuid, references restaurants)
      - `title` (text)
      - `description` (text, nullable)
      - `discount_percentage` (decimal, nullable)
      - `discount_amount` (decimal, nullable)
      - `applicable_items` (jsonb, default '[]')
      - `valid_from` (timestamptz)
      - `valid_until` (timestamptz)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on all menu tables
    - Add policies for restaurant access
*/

-- Create menu categories table
CREATE TABLE IF NOT EXISTS menu_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  revenue_center_id uuid NOT NULL REFERENCES revenue_centers(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create menu items table
CREATE TABLE IF NOT EXISTS menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES menu_categories(id) ON DELETE CASCADE,
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

-- Create combo meals table
CREATE TABLE IF NOT EXISTS combo_meals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  image_url text,
  items jsonb DEFAULT '[]',
  is_available boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create daily deals table
CREATE TABLE IF NOT EXISTS daily_deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  discount_percentage decimal(5,2),
  discount_amount decimal(10,2),
  applicable_items jsonb DEFAULT '[]',
  valid_from timestamptz NOT NULL,
  valid_until timestamptz NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_deals ENABLE ROW LEVEL SECURITY;

-- Create policies for menu_categories
CREATE POLICY "Restaurant users can manage their menu categories"
  ON menu_categories
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = menu_categories.restaurant_id
    )
  );

-- Create policies for menu_items
CREATE POLICY "Restaurant users can manage their menu items"
  ON menu_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = menu_items.restaurant_id
    )
  );

-- Create policies for combo_meals
CREATE POLICY "Restaurant users can manage their combo meals"
  ON combo_meals
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = combo_meals.restaurant_id
    )
  );

-- Create policies for daily_deals
CREATE POLICY "Restaurant users can manage their daily deals"
  ON daily_deals
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.auth_user_id = auth.uid() 
      AND users.restaurant_id = daily_deals.restaurant_id
    )
  );

-- Create updated_at triggers
CREATE TRIGGER update_menu_categories_updated_at
  BEFORE UPDATE ON menu_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at
  BEFORE UPDATE ON menu_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_combo_meals_updated_at
  BEFORE UPDATE ON combo_meals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_deals_updated_at
  BEFORE UPDATE ON daily_deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();