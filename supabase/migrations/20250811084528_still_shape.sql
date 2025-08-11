/*
  # Create default super admin user

  1. Create super admin user in auth.users
  2. Create corresponding record in users table
  3. Set up initial permissions

  Note: This creates the default super admin account
  Email: admin@kitchenpos.com
  Password: SuperAdmin123!
*/

-- Insert super admin user (this will be handled by the create-super-admin script)
-- This migration file serves as documentation of the required super admin setup

-- The super admin user should be created with:
-- - Email: admin@kitchenpos.com  
-- - Password: SuperAdmin123!
-- - Role: super_admin
-- - No restaurant_id (can access all restaurants)

-- This is typically done via the auth.admin API or the create-super-admin script
-- rather than direct SQL insertion due to password hashing requirements

-- Example of what the users table record should look like:
/*
INSERT INTO users (
  auth_user_id,
  email,
  full_name,
  role,
  restaurant_id,
  is_active
) VALUES (
  'auth-user-uuid-from-supabase-auth',
  'admin@kitchenpos.com',
  'Super Administrator',
  'super_admin',
  NULL,
  true
);
*/

-- Note: Run the create-super-admin.js script after applying migrations
-- to properly create the super admin user with correct authentication