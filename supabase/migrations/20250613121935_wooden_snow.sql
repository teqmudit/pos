/*
  # Create Default Super Admin User

  1. New Data
    - Creates a default super admin user in the users table
    - Email: admin@kitchenpos.com
    - Password: SuperAdmin123! (should be changed after first login)
    
  2. Security
    - User has super_admin role with full system access
    - No restaurant_id as super admin manages all restaurants
*/

-- Insert super admin user (this assumes you've already created the auth user)
-- You'll need to replace 'YOUR_AUTH_USER_ID' with the actual auth user ID from Supabase Auth

-- First, let's create a function to safely insert the super admin if it doesn't exist
DO $$
DECLARE
    admin_email TEXT := 'admin@kitchenpos.com';
    admin_name TEXT := 'Super Administrator';
BEGIN
    -- Check if super admin already exists
    IF NOT EXISTS (
        SELECT 1 FROM users WHERE email = admin_email AND role = 'super_admin'
    ) THEN
        -- Insert super admin user
        -- Note: You'll need to manually create the auth user first in Supabase Auth Dashboard
        -- or use the Supabase CLI/API, then update the auth_user_id below
        INSERT INTO users (
            email,
            full_name,
            role,
            restaurant_id,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            admin_email,
            admin_name,
            'super_admin',
            NULL, -- Super admin doesn't belong to any specific restaurant
            true,
            now(),
            now()
        );
        
        RAISE NOTICE 'Super admin user created with email: %', admin_email;
    ELSE
        RAISE NOTICE 'Super admin user already exists';
    END IF;
END $$;