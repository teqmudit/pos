import React, { useState } from 'react'
import { loadStripe } from '@stripe/stripe-js'
import {
  Elements,
  CardElement,
  useStripe,
  useElements
} from '@stripe/react-stripe-js'
import { CreditCard, Lock } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'
import toast from 'react-hot-toast'
import { SUBSCRIPTION_PLANS, formatPrice, type SubscriptionPlan } from '../lib/stripe'

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY!)

interface CheckoutFormProps {
  selectedPlan: SubscriptionPlan
  customerData: {
    email: string
    full_name: string
    phone_number?: string
  }
  onSuccess: (result: any) => void
  onError: (error: string) => void
}

function CheckoutForm({ selectedPlan, customerData, onSuccess, onError }: CheckoutFormProps) {
  const stripe = useStripe()
  const elements = useElements()
  const [isProcessing, setIsProcessing] = useState(false)

  const plan = SUBSCRIPTION_PLANS[selectedPlan]

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()

    if (!stripe || !elements) {
      return
    }

    setIsProcessing(true)

    try {
      // Create payment intent
      const paymentIntentResponse = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/create-payment-intent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({
            amount: plan.price,
            currency: 'usd',
            subscription_plan: selectedPlan,
            customer_email: customerData.email,
            customer_name: customerData.full_name,
            metadata: {
              phone_number: customerData.phone_number || ''
            }
          }),
        }
      )

      const { client_secret, customer_id, error: paymentIntentError } = await paymentIntentResponse.json()

      if (paymentIntentError) {
        throw new Error(paymentIntentError)
      }

      // Confirm payment
      const cardElement = elements.getElement(CardElement)
      if (!cardElement) {
        throw new Error('Card element not found')
      }

      const { error: confirmError, paymentIntent } = await stripe.confirmCardPayment(
        client_secret,
        {
          payment_method: {
            card: cardElement,
            billing_details: {
              name: customerData.full_name,
              email: customerData.email,
            },
          },
        }
      )

      if (confirmError) {
        throw new Error(confirmError.message)
      }

      if (paymentIntent?.status === 'succeeded') {
        // Create subscription
        const subscriptionResponse = await fetch(
          `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/create-subscription`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
            },
            body: JSON.stringify({
              customer_id,
              price_id: plan.priceId,
              payment_method_id: paymentIntent.payment_method,
              subscription_plan: selectedPlan,
              kitchen_owner_data: customerData
            }),
          }
        )

        const subscriptionResult = await subscriptionResponse.json()

        if (subscriptionResult.error) {
          throw new Error(subscriptionResult.error)
        }

        onSuccess(subscriptionResult)
      }

    } catch (error) {
      console.error('Payment error:', error)
      onError(error instanceof Error ? error.message : 'Payment failed')
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Plan Summary */}
      <div className="bg-primary-50 rounded-lg p-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-semibold text-primary-900">{plan.name}</h3>
          <span className="text-2xl font-bold text-primary-600">
            {formatPrice(plan.price)}/month
          </span>
        </div>
        <ul className="text-sm text-primary-700 space-y-1">
          {plan.features.map((feature, index) => (
            <li key={index} className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-primary-600 rounded-full" />
              {feature}
            </li>
          ))}
        </ul>
      </div>

      {/* Card Details */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          <div className="flex items-center gap-2">
            <CreditCard className="h-4 w-4" />
            Card Details
          </div>
        </label>
        <div className="border border-gray-300 rounded-lg p-3">
          <CardElement
            options={{
              style: {
                base: {
                  fontSize: '16px',
                  color: '#424770',
                  '::placeholder': {
                    color: '#aab7c4',
                  },
                },
              },
            }}
          />
        </div>
      </div>

      {/* Security Notice */}
      <div className="flex items-center gap-2 text-sm text-gray-600">
        <Lock className="h-4 w-4" />
        <span>Your payment information is secure and encrypted</span>
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        disabled={!stripe || isProcessing}
        className="btn-primary btn-lg w-full"
      >
        {isProcessing ? (
          <div className="flex items-center justify-center gap-2">
            <LoadingSpinner size="sm" />
            <span>Processing Payment...</span>
          </div>
        ) : (
          `Subscribe for ${formatPrice(plan.price)}/month`
        )}
      </button>
    </form>
  )
}

interface StripeCheckoutProps {
  selectedPlan: SubscriptionPlan
  customerData: {
    email: string
    full_name: string
    phone_number?: string
  }
  onSuccess: (result: any) => void
  onError: (error: string) => void
}

export default function StripeCheckout({ selectedPlan, customerData, onSuccess, onError }: StripeCheckoutProps) {
  return (
    <Elements stripe={stripePromise}>
      <CheckoutForm
        selectedPlan={selectedPlan}
        customerData={customerData}
        onSuccess={onSuccess}
        onError={onError}
      />
    </Elements>
  )
}