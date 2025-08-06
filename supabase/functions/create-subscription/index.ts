import { createClient } from 'npm:@supabase/supabase-js@2.39.3'
import Stripe from 'npm:stripe@14.21.0'
import { corsHeaders } from '../_shared/cors.ts'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

interface CreateSubscriptionRequest {
  customer_id: string
  price_id: string
  payment_method_id: string
  subscription_plan: 'basic' | 'premium' | 'enterprise'
  kitchen_owner_data: {
    email: string
    full_name: string
    phone_number?: string
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        {
          status: 405,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const {
      customer_id,
      price_id,
      payment_method_id,
      subscription_plan,
      kitchen_owner_data
    }: CreateSubscriptionRequest = await req.json()

    // Attach payment method to customer
    await stripe.paymentMethods.attach(payment_method_id, {
      customer: customer_id,
    })

    // Update customer's default payment method
    await stripe.customers.update(customer_id, {
      invoice_settings: {
        default_payment_method: payment_method_id,
      },
    })

    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer_id,
      items: [{ price: price_id }],
      default_payment_method: payment_method_id,
      expand: ['latest_invoice.payment_intent'],
    })

    // Generate random password for kitchen owner
    const generatePassword = () => {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
      let password = ''
      for (let i = 0; i < 12; i++) {
        password += chars.charAt(Math.floor(Math.random() * chars.length))
      }
      return password
    }

    const randomPassword = generatePassword()

    // Create auth user
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: kitchen_owner_data.email,
      password: randomPassword,
      email_confirm: true,
      user_metadata: {
        full_name: kitchen_owner_data.full_name,
        role: 'kitchen_owner'
      }
    })

    if (authError) {
      console.error('Error creating auth user:', authError)
      // Cancel the subscription if user creation fails
      await stripe.subscriptions.cancel(subscription.id)
      throw new Error('Failed to create user account')
    }

    // Create kitchen owner record
    const { data: kitchenOwner, error: kitchenOwnerError } = await supabase
      .from('kitchen_owners')
      .insert({
        user_id: authUser.user.id,
        email: kitchen_owner_data.email,
        full_name: kitchen_owner_data.full_name,
        subscription_plan,
        payment_id: subscription.id,
        subscription_amount: subscription.items.data[0].price.unit_amount! / 100,
        subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
        password_hash: randomPassword, // In production, hash this properly
        is_setup_completed: false
      })
      .select()
      .single()

    if (kitchenOwnerError) {
      console.error('Error creating kitchen owner:', kitchenOwnerError)
      // Clean up auth user and subscription
      await supabase.auth.admin.deleteUser(authUser.user.id)
      await stripe.subscriptions.cancel(subscription.id)
      throw new Error('Failed to create kitchen owner record')
    }

    // Create user record
    const { error: userError } = await supabase
      .from('users')
      .insert({
        auth_user_id: authUser.user.id,
        email: kitchen_owner_data.email,
        full_name: kitchen_owner_data.full_name,
        role: 'kitchen_owner',
        is_active: true
      })

    if (userError) {
      console.error('Error creating user record:', userError)
    }

    return new Response(
      JSON.stringify({
        subscription_id: subscription.id,
        status: subscription.status,
        client_secret: subscription.latest_invoice?.payment_intent?.client_secret,
        kitchen_owner_id: kitchenOwner.id,
        credentials: {
          email: kitchen_owner_data.email,
          password: randomPassword
        }
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error creating subscription:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Failed to create subscription',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})