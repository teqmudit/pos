import { supabase } from '../lib/supabase'

export interface SubscriptionInfo {
  id: string
  plan: 'basic' | 'premium' | 'enterprise'
  status: 'active' | 'inactive' | 'cancelled' | 'past_due'
  current_period_end: string
  amount: number
  payment_id: string
}

export class SubscriptionService {
  static async getCurrentSubscription(kitchenOwnerId: string): Promise<SubscriptionInfo | null> {
    const { data, error } = await supabase
      .from('kitchen_owners')
      .select('subscription_plan, subscription_amount, subscription_expires_at, payment_id')
      .eq('id', kitchenOwnerId)
      .single()

    if (error || !data) {
      return null
    }

    // Check if subscription is active
    const isActive = new Date(data.subscription_expires_at) > new Date()

    return {
      id: data.payment_id,
      plan: data.subscription_plan,
      status: isActive ? 'active' : 'inactive',
      current_period_end: data.subscription_expires_at,
      amount: data.subscription_amount,
      payment_id: data.payment_id
    }
  }

  static async cancelSubscription(subscriptionId: string): Promise<void> {
    const response = await fetch(
      `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/cancel-subscription`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ subscription_id: subscriptionId }),
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Failed to cancel subscription')
    }
  }

  static async updateSubscription(subscriptionId: string, newPriceId: string): Promise<void> {
    const response = await fetch(
      `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/update-subscription`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ 
          subscription_id: subscriptionId,
          new_price_id: newPriceId 
        }),
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Failed to update subscription')
    }
  }

  static async getUsageStats(restaurantId: string): Promise<{
    ordersThisMonth: number
    orderLimit: number
    percentageUsed: number
  }> {
    const startOfMonth = new Date()
    startOfMonth.setDate(1)
    startOfMonth.setHours(0, 0, 0, 0)

    const { count, error } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .eq('restaurant_id', restaurantId)
      .gte('created_at', startOfMonth.toISOString())

    if (error) {
      console.error('Error fetching usage stats:', error)
      return { ordersThisMonth: 0, orderLimit: 0, percentageUsed: 0 }
    }

    // Get subscription info to determine limits
    const { data: restaurant } = await supabase
      .from('restaurants')
      .select('kitchen_owners(subscription_plan)')
      .eq('id', restaurantId)
      .single()

    const plan = restaurant?.kitchen_owners?.subscription_plan || 'basic'
    
    const limits = {
      basic: 100,
      premium: 500,
      enterprise: Infinity
    }

    const orderLimit = limits[plan as keyof typeof limits]
    const ordersThisMonth = count || 0
    const percentageUsed = orderLimit === Infinity ? 0 : (ordersThisMonth / orderLimit) * 100

    return {
      ordersThisMonth,
      orderLimit,
      percentageUsed
    }
  }
}