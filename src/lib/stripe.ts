import { loadStripe } from '@stripe/stripe-js'

// Initialize Stripe
export const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY!)

// Subscription plans
export const SUBSCRIPTION_PLANS = {
  basic: {
    id: 'basic',
    name: 'Basic Plan',
    price: 2999, // $29.99 in cents
    priceId: 'price_basic_monthly', // Replace with actual Stripe price ID
    features: [
      'Up to 100 orders per month',
      'Basic menu management',
      'Email support',
      'Single location'
    ]
  },
  premium: {
    id: 'premium',
    name: 'Premium Plan',
    price: 4999, // $49.99 in cents
    priceId: 'price_premium_monthly', // Replace with actual Stripe price ID
    features: [
      'Up to 500 orders per month',
      'Advanced menu management',
      'Priority support',
      'Multiple locations',
      'Analytics dashboard'
    ]
  },
  enterprise: {
    id: 'enterprise',
    name: 'Enterprise Plan',
    price: 9999, // $99.99 in cents
    priceId: 'price_enterprise_monthly', // Replace with actual Stripe price ID
    features: [
      'Unlimited orders',
      'Full feature access',
      '24/7 phone support',
      'Custom integrations',
      'Advanced analytics',
      'White-label options'
    ]
  }
} as const

export type SubscriptionPlan = keyof typeof SUBSCRIPTION_PLANS

// Format price for display
export const formatPrice = (cents: number): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(cents / 100)
}