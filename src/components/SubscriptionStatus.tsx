import React, { useEffect, useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { SubscriptionService, type SubscriptionInfo } from '../services/subscriptionService'
import { formatPrice, SUBSCRIPTION_PLANS } from '../lib/stripe'
import { Crown, AlertTriangle, CheckCircle, Calendar } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'
import { format } from 'date-fns'

export default function SubscriptionStatus() {
  const { user } = useAuth()
  const [subscription, setSubscription] = useState<SubscriptionInfo | null>(null)
  const [usageStats, setUsageStats] = useState<{
    ordersThisMonth: number
    orderLimit: number
    percentageUsed: number
  } | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user?.role === 'kitchen_owner' && user.restaurant_id) {
      fetchSubscriptionData()
    }
  }, [user])

  const fetchSubscriptionData = async () => {
    try {
      setLoading(true)

      // Get kitchen owner ID
      const { data: kitchenOwner } = await supabase
        .from('kitchen_owners')
        .select('id')
        .eq('user_id', user?.id)
        .single()

      if (kitchenOwner) {
        const [subscriptionData, usageData] = await Promise.all([
          SubscriptionService.getCurrentSubscription(kitchenOwner.id),
          SubscriptionService.getUsageStats(user?.restaurant_id!)
        ])

        setSubscription(subscriptionData)
        setUsageStats(usageData)
      }
    } catch (error) {
      console.error('Error fetching subscription data:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="card">
        <div className="card-content">
          <div className="flex items-center justify-center py-4">
            <LoadingSpinner size="md" />
          </div>
        </div>
      </div>
    )
  }

  if (!subscription) {
    return (
      <div className="card border-warning-200">
        <div className="card-content">
          <div className="flex items-center gap-3">
            <AlertTriangle className="h-6 w-6 text-warning-600" />
            <div>
              <h3 className="font-semibold text-warning-800">No Active Subscription</h3>
              <p className="text-sm text-warning-700">Please contact support to activate your subscription.</p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  const plan = SUBSCRIPTION_PLANS[subscription.plan]
  const isExpiringSoon = new Date(subscription.current_period_end) < new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)

  return (
    <div className="space-y-4">
      {/* Subscription Info */}
      <div className={`card ${subscription.status === 'active' ? 'border-success-200' : 'border-warning-200'}`}>
        <div className="card-content">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-full ${
                subscription.status === 'active' ? 'bg-success-100' : 'bg-warning-100'
              }`}>
                {subscription.status === 'active' ? (
                  <CheckCircle className="h-5 w-5 text-success-600" />
                ) : (
                  <AlertTriangle className="h-5 w-5 text-warning-600" />
                )}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-gray-900">{plan.name}</h3>
                  {subscription.plan === 'premium' && (
                    <Crown className="h-4 w-4 text-warning-500" />
                  )}
                </div>
                <p className="text-sm text-gray-600">
                  {formatPrice(subscription.amount * 100)}/month
                </p>
              </div>
            </div>
            <div className="text-right">
              <span className={`badge ${
                subscription.status === 'active' ? 'badge-success' : 'badge-warning'
              }`}>
                {subscription.status}
              </span>
              {isExpiringSoon && (
                <p className="text-xs text-warning-600 mt-1">
                  Expires soon
                </p>
              )}
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-gray-200">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Calendar className="h-4 w-4" />
              <span>
                Next billing: {format(new Date(subscription.current_period_end), 'MMM dd, yyyy')}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Usage Stats */}
      {usageStats && usageStats.orderLimit !== Infinity && (
        <div className="card">
          <div className="card-header">
            <h3 className="font-semibold text-gray-900">Monthly Usage</h3>
          </div>
          <div className="card-content">
            <div className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Orders this month</span>
                <span className="font-medium">
                  {usageStats.ordersThisMonth} / {usageStats.orderLimit}
                </span>
              </div>
              
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className={`h-2 rounded-full transition-all duration-300 ${
                    usageStats.percentageUsed > 90 
                      ? 'bg-error-600' 
                      : usageStats.percentageUsed > 75 
                        ? 'bg-warning-600' 
                        : 'bg-success-600'
                  }`}
                  style={{ width: `${Math.min(usageStats.percentageUsed, 100)}%` }}
                />
              </div>
              
              <p className="text-xs text-gray-500">
                {usageStats.percentageUsed.toFixed(1)}% of monthly limit used
              </p>

              {usageStats.percentageUsed > 90 && (
                <div className="bg-warning-50 border border-warning-200 rounded-lg p-3">
                  <p className="text-sm text-warning-800">
                    You're approaching your monthly order limit. Consider upgrading your plan.
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}