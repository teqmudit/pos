import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check, Star, ArrowRight } from 'lucide-react'
import { SUBSCRIPTION_PLANS, formatPrice, type SubscriptionPlan } from '../lib/stripe'
import StripeCheckout from '../components/StripeCheckout'
import toast from 'react-hot-toast'

export default function PricingPage() {
  const navigate = useNavigate()
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null)
  const [showCheckout, setShowCheckout] = useState(false)
  const [customerData, setCustomerData] = useState({
    email: '',
    full_name: '',
    phone_number: ''
  })

  const handlePlanSelect = (planId: SubscriptionPlan) => {
    setSelectedPlan(planId)
    setShowCheckout(true)
  }

  const handlePaymentSuccess = (result: any) => {
    toast.success('Subscription created successfully!')
    console.log('Payment successful:', result)
    
    // Show credentials to user
    if (result.credentials) {
      toast.success(
        `Account created! Email: ${result.credentials.email}, Password: ${result.credentials.password}`,
        { duration: 10000 }
      )
    }
    
    // Redirect to login
    setTimeout(() => {
      navigate('/login')
    }, 3000)
  }

  const handlePaymentError = (error: string) => {
    toast.error(`Payment failed: ${error}`)
    setShowCheckout(false)
  }

  if (showCheckout && selectedPlan) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full">
          <div className="card">
            <div className="card-header">
              <h2 className="text-xl font-semibold text-gray-900">Complete Your Subscription</h2>
              <button
                onClick={() => setShowCheckout(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ← Back to Plans
              </button>
            </div>
            <div className="card-content">
              {/* Customer Info Form */}
              <div className="space-y-4 mb-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Full Name *
                  </label>
                  <input
                    type="text"
                    required
                    className="input"
                    value={customerData.full_name}
                    onChange={(e) => setCustomerData(prev => ({ ...prev, full_name: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email Address *
                  </label>
                  <input
                    type="email"
                    required
                    className="input"
                    value={customerData.email}
                    onChange={(e) => setCustomerData(prev => ({ ...prev, email: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Phone Number
                  </label>
                  <input
                    type="tel"
                    className="input"
                    value={customerData.phone_number}
                    onChange={(e) => setCustomerData(prev => ({ ...prev, phone_number: e.target.value }))}
                  />
                </div>
              </div>

              {customerData.email && customerData.full_name && (
                <StripeCheckout
                  selectedPlan={selectedPlan}
                  customerData={customerData}
                  onSuccess={handlePaymentSuccess}
                  onError={handlePaymentError}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-primary-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Choose Your Plan
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Select the perfect plan for your kitchen. Start your journey with Kitchen POS today.
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {Object.entries(SUBSCRIPTION_PLANS).map(([planId, plan]) => {
            const isPopular = planId === 'premium'
            
            return (
              <div
                key={planId}
                className={`card hover-lift relative ${
                  isPopular ? 'ring-2 ring-primary-500' : ''
                }`}
              >
                {isPopular && (
                  <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                    <div className="bg-primary-600 text-white px-4 py-1 rounded-full text-sm font-medium flex items-center gap-1">
                      <Star className="h-4 w-4" />
                      Most Popular
                    </div>
                  </div>
                )}
                
                <div className="card-content text-center">
                  <h3 className="text-2xl font-bold text-gray-900 mb-2">
                    {plan.name}
                  </h3>
                  
                  <div className="mb-6">
                    <span className="text-4xl font-bold text-primary-600">
                      {formatPrice(plan.price)}
                    </span>
                    <span className="text-gray-600">/month</span>
                  </div>

                  <ul className="space-y-3 mb-8 text-left">
                    {plan.features.map((feature, index) => (
                      <li key={index} className="flex items-start gap-3">
                        <Check className="h-5 w-5 text-success-600 mt-0.5 flex-shrink-0" />
                        <span className="text-gray-700">{feature}</span>
                      </li>
                    ))}
                  </ul>

                  <button
                    onClick={() => handlePlanSelect(planId as SubscriptionPlan)}
                    className={`btn-lg w-full ${
                      isPopular ? 'btn-primary' : 'btn-secondary'
                    }`}
                  >
                    Get Started
                    <ArrowRight className="h-4 w-4 ml-2" />
                  </button>
                </div>
              </div>
            )
          })}
        </div>

        {/* Features Section */}
        <div className="mt-16 text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-8">
            Why Choose Kitchen POS?
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            <div className="text-center">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="h-6 w-6 text-primary-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">Easy Setup</h3>
              <p className="text-gray-600">Get started in minutes with our intuitive setup process</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="h-6 w-6 text-primary-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">24/7 Support</h3>
              <p className="text-gray-600">Our team is here to help you succeed every step of the way</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="h-6 w-6 text-primary-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">Secure & Reliable</h3>
              <p className="text-gray-600">Bank-level security with 99.9% uptime guarantee</p>
            </div>
          </div>
        </div>

        {/* Back to Login */}
        <div className="text-center mt-12">
          <button
            onClick={() => navigate('/login')}
            className="text-primary-600 hover:text-primary-700 font-medium"
          >
            Already have an account? Sign in
          </button>
        </div>
      </div>
    </div>
  )
}