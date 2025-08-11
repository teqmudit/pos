/*
  # Create utility functions and triggers

  1. Functions
    - Function to update customer order statistics
    - Function to generate order numbers
    - Function to check business hours

  2. Triggers
    - Trigger to update customer stats when orders are created/updated
    - Trigger to validate order items
*/

-- Function to update customer order statistics
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update customer statistics when order status changes to 'served'
  IF NEW.status = 'served' AND (OLD.status IS NULL OR OLD.status != 'served') THEN
    UPDATE customers 
    SET 
      total_orders = total_orders + 1,
      total_spent = total_spent + NEW.total_amount,
      last_order_at = NEW.updated_at
    WHERE id = NEW.customer_id;
  END IF;
  
  -- Decrease customer statistics when order is cancelled after being served
  IF OLD.status = 'served' AND NEW.status = 'cancelled' THEN
    UPDATE customers 
    SET 
      total_orders = GREATEST(total_orders - 1, 0),
      total_spent = GREATEST(total_spent - NEW.total_amount, 0)
    WHERE id = NEW.customer_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for customer stats update
CREATE TRIGGER update_customer_stats_trigger
  AFTER UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.customer_id IS NOT NULL)
  EXECUTE FUNCTION update_customer_stats();

-- Function to generate unique order numbers
CREATE OR REPLACE FUNCTION generate_order_number(restaurant_uuid uuid)
RETURNS text AS $$
DECLARE
  date_prefix text;
  order_count integer;
  order_number text;
BEGIN
  -- Get today's date in YYYYMMDD format
  date_prefix := to_char(CURRENT_DATE, 'YYYYMMDD');
  
  -- Get count of orders for today for this restaurant
  SELECT COUNT(*) INTO order_count
  FROM orders 
  WHERE restaurant_id = restaurant_uuid
  AND DATE(created_at) = CURRENT_DATE;
  
  -- Generate order number
  order_number := date_prefix || '-' || LPAD((order_count + 1)::text, 4, '0');
  
  RETURN order_number;
END;
$$ LANGUAGE plpgsql;

-- Function to check if revenue center is open
CREATE OR REPLACE FUNCTION is_revenue_center_open(
  center_id uuid,
  check_time timestamptz DEFAULT NOW()
)
RETURNS boolean AS $$
DECLARE
  day_of_week_num integer;
  current_time time;
  business_hour record;
BEGIN
  -- Get day of week (0 = Sunday, 1 = Monday, etc.)
  day_of_week_num := EXTRACT(DOW FROM check_time);
  
  -- Get current time
  current_time := check_time::time;
  
  -- Get business hours for this day
  SELECT * INTO business_hour
  FROM business_hours
  WHERE revenue_center_id = center_id
  AND day_of_week = day_of_week_num;
  
  -- If no business hours found, assume closed
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- If marked as closed, return false
  IF business_hour.is_closed THEN
    RETURN false;
  END IF;
  
  -- If no open/close times set, assume closed
  IF business_hour.open_time IS NULL OR business_hour.close_time IS NULL THEN
    RETURN false;
  END IF;
  
  -- Handle overnight hours (e.g., 22:00 to 02:00)
  IF business_hour.close_time < business_hour.open_time THEN
    RETURN current_time >= business_hour.open_time OR current_time <= business_hour.close_time;
  ELSE
    RETURN current_time >= business_hour.open_time AND current_time <= business_hour.close_time;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to validate order items
CREATE OR REPLACE FUNCTION validate_order_item()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure either menu_item_id or combo_meal_id is set, but not both
  IF (NEW.menu_item_id IS NULL AND NEW.combo_meal_id IS NULL) OR
     (NEW.menu_item_id IS NOT NULL AND NEW.combo_meal_id IS NOT NULL) THEN
    RAISE EXCEPTION 'Order item must reference either a menu item or combo meal, but not both';
  END IF;
  
  -- Validate that the referenced item belongs to the same restaurant
  IF NEW.menu_item_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM menu_items mi
      JOIN orders o ON o.id = NEW.order_id
      WHERE mi.id = NEW.menu_item_id
      AND mi.restaurant_id = o.restaurant_id
    ) THEN
      RAISE EXCEPTION 'Menu item does not belong to the same restaurant as the order';
    END IF;
  END IF;
  
  IF NEW.combo_meal_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM combo_meals cm
      JOIN orders o ON o.id = NEW.order_id
      WHERE cm.id = NEW.combo_meal_id
      AND cm.restaurant_id = o.restaurant_id
    ) THEN
      RAISE EXCEPTION 'Combo meal does not belong to the same restaurant as the order';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order item validation
CREATE TRIGGER validate_order_item_trigger
  BEFORE INSERT OR UPDATE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION validate_order_item();

-- Function to automatically set order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set order number if it's not already set
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := generate_order_number(NEW.restaurant_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic order number generation
CREATE TRIGGER set_order_number_trigger
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_number();