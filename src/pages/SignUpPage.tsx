import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Store, Check, Upload, CreditCard, User, Building, FileText } from 'lucide-react'
import LoadingSpinner from '../components/LoadingSpinner'
import GolfCourseSelector from '../components/GolfCourseSelector'
import toast from 'react-hot-toast'

interface SignUpFormData {
  // Step 1: Sign Up
  fullName: string
  email: string
  phoneNumber: string
  password: string
  confirmPassword: string
  
  // Step 2: Kitchen Details
  kitchenName: string
  kitchenLogo: File | null
  kitchenAddress: string
  gstNumber: string
  selectedGolfCourses: string[]
  
  // Step 3: Billing Information
  panNumber: string
  bankAccountNumber: string
  ifscCode: string
  billingEmail: string
  acceptTerms: boolean
}

const initialFormData: SignUpFormData = {
  fullName: '',
  email: '',
  phoneNumber: '',
  password: '',
  confirmPassword: '',
  kitchenName: '',
  kitchenLogo: null,
  kitchenAddress: '',
  gstNumber: '',
  selectedGolfCourses: [],
  panNumber: '',
  bankAccountNumber: '',
  ifscCode: '',
  billingEmail: '',
  acceptTerms: false
}

export default function SignUpPage() {
  const navigate = useNavigate()
  const [currentStep, setCurrentStep] = useState(1)
  const [formData, setFormData] = useState<SignUpFormData>(initialFormData)
  const [isLoading, setIsLoading] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const steps = [
    { number: 1, title: 'Sign Up', icon: User },
    { number: 2, title: 'Kitchen Details', icon: Building },
    { number: 3, title: 'Billing Information', icon: CreditCard },
    { number: 4, title: 'Success', icon: Check }
  ]

  const handleInputChange = (field: keyof SignUpFormData, value: string | boolean | File | null) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }))
    }
  }

  const validateStep1 = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!formData.fullName.trim()) {
      newErrors.fullName = 'Full name is required'
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required'
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email'
    }

    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = 'Phone number is required'
    }

    if (!formData.password) {
      newErrors.password = 'Password is required'
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters'
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password'
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const validateStep2 = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!formData.kitchenName.trim()) {
      newErrors.kitchenName = 'Kitchen name is required'
    }

    if (!formData.kitchenAddress.trim()) {
      newErrors.kitchenAddress = 'Kitchen address is required'
    }

    if (formData.selectedGolfCourses.length === 0) {
      newErrors.selectedGolfCourses = 'Please select at least one golf course to serve'
    }
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const validateStep3 = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!formData.panNumber.trim()) {
      newErrors.panNumber = 'PAN number is required'
    }

    if (!formData.bankAccountNumber.trim()) {
      newErrors.bankAccountNumber = 'Bank account number is required'
    }

    if (!formData.ifscCode.trim()) {
      newErrors.ifscCode = 'IFSC code is required'
    }

    if (!formData.billingEmail.trim()) {
      newErrors.billingEmail = 'Billing email is required'
    } else if (!/\S+@\S+\.\S+/.test(formData.billingEmail)) {
      newErrors.billingEmail = 'Please enter a valid email'
    }

    if (!formData.acceptTerms) {
      newErrors.acceptTerms = 'You must accept the terms and conditions'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleContinue = () => {
    let isValid = false

    switch (currentStep) {
      case 1:
        isValid = validateStep1()
        break
      case 2:
        isValid = validateStep2()
        break
      case 3:
        isValid = validateStep3()
        break
      default:
        isValid = true
    }

    if (isValid) {
      if (currentStep === 3) {
        handleSignUp()
      } else {
        setCurrentStep(prev => prev + 1)
      }
    }
  }

  const handleSignUp = async () => {
    setIsLoading(true)

    try {
      // Simulate Stripe API call
      const response = await fetch('/api/stripe/create-connected-account', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email,
          business_type: 'individual',
          country: 'IN',
          account_holder_name: formData.fullName,
          bank_account: {
            account_number: formData.bankAccountNumber,
            routing_number: formData.ifscCode,
          },
          golf_courses: formData.selectedGolfCourses,
          business_profile: {
            name: formData.kitchenName,
            support_email: formData.billingEmail,
          }
        }),
      })

      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 2000))

      if (Math.random() > 0.2) { // 80% success rate for demo
        toast.success('Registration successful!')
        setCurrentStep(4)
      } else {
        throw new Error('Failed to create Stripe account')
      }
    } catch (error) {
      console.error('Registration error:', error)
      toast.error('Registration failed. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoToDashboard = () => {
    navigate('/login')
  }

  const renderProgressBar = () => (
    <div className="mb-8">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => {
          const IconComponent = step.icon
          const isActive = currentStep === step.number
          const isCompleted = currentStep > step.number
          
          return (
            <div key={step.number} className="flex items-center">
              <div className={`flex items-center justify-center w-10 h-10 rounded-full border-2 ${
                isCompleted 
                  ? 'bg-success-600 border-success-600 text-white' 
                  : isActive 
                    ? 'bg-primary-600 border-primary-600 text-white' 
                    : 'bg-white border-gray-300 text-gray-400'
              }`}>
                {isCompleted ? (
                  <Check className="h-5 w-5" />
                ) : (
                  <IconComponent className="h-5 w-5" />
                )}
              </div>
              <div className="ml-3 hidden sm:block">
                <p className={`text-sm font-medium ${
                  isActive ? 'text-primary-600' : isCompleted ? 'text-success-600' : 'text-gray-500'
                }`}>
                  {step.title}
                </p>
              </div>
              {index < steps.length - 1 && (
                <div className={`flex-1 h-0.5 mx-4 ${
                  isCompleted ? 'bg-success-600' : 'bg-gray-300'
                }`} />
              )}
            </div>
          )
        })}
      </div>
    </div>
  )

  const renderStep1 = () => (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Create Your Account</h2>
        <p className="text-gray-600 mt-2">Enter your personal information to get started</p>
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Full Name *
          </label>
          <input
            type="text"
            className={`input ${errors.fullName ? 'border-error-500' : ''}`}
            placeholder="Enter your full name"
            value={formData.fullName}
            onChange={(e) => handleInputChange('fullName', e.target.value)}
          />
          {errors.fullName && (
            <p className="text-error-600 text-sm mt-1">{errors.fullName}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Email Address *
          </label>
          <input
            type="email"
            className={`input ${errors.email ? 'border-error-500' : ''}`}
            placeholder="Enter your email address"
            value={formData.email}
            onChange={(e) => handleInputChange('email', e.target.value)}
          />
          {errors.email && (
            <p className="text-error-600 text-sm mt-1">{errors.email}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Phone Number *
          </label>
          <input
            type="tel"
            className={`input ${errors.phoneNumber ? 'border-error-500' : ''}`}
            placeholder="Enter your phone number"
            value={formData.phoneNumber}
            onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
          />
          {errors.phoneNumber && (
            <p className="text-error-600 text-sm mt-1">{errors.phoneNumber}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Password *
          </label>
          <input
            type="password"
            className={`input ${errors.password ? 'border-error-500' : ''}`}
            placeholder="Create a password"
            value={formData.password}
            onChange={(e) => handleInputChange('password', e.target.value)}
          />
          {errors.password && (
            <p className="text-error-600 text-sm mt-1">{errors.password}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Confirm Password *
          </label>
          <input
            type="password"
            className={`input ${errors.confirmPassword ? 'border-error-500' : ''}`}
            placeholder="Confirm your password"
            value={formData.confirmPassword}
            onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
          />
          {errors.confirmPassword && (
            <p className="text-error-600 text-sm mt-1">{errors.confirmPassword}</p>
          )}
        </div>
      </div>
    </div>
  )

  const renderStep2 = () => (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Kitchen Details</h2>
        <p className="text-gray-600 mt-2">Tell us about your kitchen</p>
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Kitchen Name *
          </label>
          <input
            type="text"
            className={`input ${errors.kitchenName ? 'border-error-500' : ''}`}
            placeholder="Enter your kitchen name"
            value={formData.kitchenName}
            onChange={(e) => handleInputChange('kitchenName', e.target.value)}
          />
          {errors.kitchenName && (
            <p className="text-error-600 text-sm mt-1">{errors.kitchenName}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Kitchen Logo
          </label>
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-primary-500 transition-colors">
            <Upload className="h-8 w-8 text-gray-400 mx-auto mb-2" />
            <p className="text-sm text-gray-600 mb-2">
              Click to upload or drag and drop
            </p>
            <p className="text-xs text-gray-500">PNG, JPG up to 2MB</p>
            <input
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => handleInputChange('kitchenLogo', e.target.files?.[0] || null)}
            />
          </div>
          {formData.kitchenLogo && (
            <p className="text-sm text-success-600 mt-1">
              Selected: {formData.kitchenLogo.name}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Kitchen Address *
          </label>
          <textarea
            rows={4}
            className={`input resize-none ${errors.kitchenAddress ? 'border-error-500' : ''}`}
            placeholder="Enter your complete kitchen address"
            value={formData.kitchenAddress}
            onChange={(e) => handleInputChange('kitchenAddress', e.target.value)}
          />
          {errors.kitchenAddress && (
            <p className="text-error-600 text-sm mt-1">{errors.kitchenAddress}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            GST Number (Optional)
          </label>
          <input
            type="text"
            className="input"
            placeholder="Enter GST number if applicable"
            value={formData.gstNumber}
            onChange={(e) => handleInputChange('gstNumber', e.target.value)}
          />
        </div>
      </div>
        <div>
          <GolfCourseSelector
            selectedCourses={formData.selectedGolfCourses}
            onSelectionChange={(courseIds) => handleInputChange('selectedGolfCourses', courseIds)}
          />
          {errors.selectedGolfCourses && (
            <p className="text-error-600 text-sm mt-1">{errors.selectedGolfCourses}</p>
          )}
        </div>
    </div>
  )

  const renderStep3 = () => (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Billing Information</h2>
        <p className="text-gray-600 mt-2">Provide your billing and bank details</p>
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            PAN Number *
          </label>
          <input
            type="text"
            className={`input ${errors.panNumber ? 'border-error-500' : ''}`}
            placeholder="Enter PAN number"
            value={formData.panNumber}
            onChange={(e) => handleInputChange('panNumber', e.target.value.toUpperCase())}
          />
          {errors.panNumber && (
            <p className="text-error-600 text-sm mt-1">{errors.panNumber}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Bank Account Number *
          </label>
          <input
            type="text"
            className={`input ${errors.bankAccountNumber ? 'border-error-500' : ''}`}
            placeholder="Enter bank account number"
            value={formData.bankAccountNumber}
            onChange={(e) => handleInputChange('bankAccountNumber', e.target.value)}
          />
          {errors.bankAccountNumber && (
            <p className="text-error-600 text-sm mt-1">{errors.bankAccountNumber}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            IFSC Code *
          </label>
          <input
            type="text"
            className={`input ${errors.ifscCode ? 'border-error-500' : ''}`}
            placeholder="Enter IFSC code"
            value={formData.ifscCode}
            onChange={(e) => handleInputChange('ifscCode', e.target.value.toUpperCase())}
          />
          {errors.ifscCode && (
            <p className="text-error-600 text-sm mt-1">{errors.ifscCode}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Billing Email *
          </label>
          <input
            type="email"
            className={`input ${errors.billingEmail ? 'border-error-500' : ''}`}
            placeholder="Enter billing email address"
            value={formData.billingEmail}
            onChange={(e) => handleInputChange('billingEmail', e.target.value)}
          />
          {errors.billingEmail && (
            <p className="text-error-600 text-sm mt-1">{errors.billingEmail}</p>
          )}
        </div>

        <div className="flex items-start gap-3">
          <input
            type="checkbox"
            id="acceptTerms"
            className="mt-1 rounded border-gray-300"
            checked={formData.acceptTerms}
            onChange={(e) => handleInputChange('acceptTerms', e.target.checked)}
          />
          <label htmlFor="acceptTerms" className="text-sm text-gray-700">
            I accept the{' '}
            <a href="#" className="text-primary-600 hover:text-primary-700">
              Terms and Conditions
            </a>{' '}
            and{' '}
            <a href="#" className="text-primary-600 hover:text-primary-700">
              Privacy Policy
            </a>
          </label>
        </div>
        {errors.acceptTerms && (
          <p className="text-error-600 text-sm">{errors.acceptTerms}</p>
        )}
      </div>
    </div>
  )

  const renderStep4 = () => (
    <div className="text-center space-y-6">
      <div className="flex justify-center">
        <div className="w-20 h-20 bg-success-100 rounded-full flex items-center justify-center">
          <Check className="h-10 w-10 text-success-600" />
        </div>
      </div>
      
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Registration Successful!</h2>
        <p className="text-gray-600">
          Your account has been created successfully. You can now access your dashboard.
        </p>
      </div>

      <button
        onClick={handleGoToDashboard}
        className="btn-primary btn-lg"
      >
        Go to Dashboard
      </button>
    </div>
  )

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <div className="flex justify-center">
            <div className="flex items-center justify-center w-16 h-16 bg-primary-600 rounded-2xl shadow-lg">
              <Store className="h-8 w-8 text-white" />
            </div>
          </div>
          <h1 className="mt-6 text-3xl font-bold text-gray-900">
            Kitchen POS Registration
          </h1>
        </div>

        {/* Progress Bar */}
        {renderProgressBar()}

        {/* Form Card */}
        <div className="card">
          <div className="card-content">
            {currentStep === 1 && renderStep1()}
            {currentStep === 2 && renderStep2()}
            {currentStep === 3 && renderStep3()}
            {currentStep === 4 && renderStep4()}

            {/* Navigation Buttons */}
            {currentStep < 4 && (
              <div className="flex gap-4 pt-6">
                {currentStep > 1 && (
                  <button
                    type="button"
                    onClick={() => setCurrentStep(prev => prev - 1)}
                    className="btn-secondary btn-lg flex-1"
                    disabled={isLoading}
                  >
                    Back
                  </button>
                )}
                <button
                  onClick={handleContinue}
                  disabled={isLoading}
                  className="btn-primary btn-lg flex-1"
                >
                  {isLoading ? (
                    <div className="flex items-center justify-center gap-2">
                      <LoadingSpinner size="sm" />
                      <span>Processing...</span>
                    </div>
                  ) : currentStep === 3 ? (
                    'Sign Up'
                  ) : (
                    'Continue'
                  )}
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Login Link */}
        {currentStep === 1 && (
          <div className="text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <button
                onClick={() => navigate('/login')}
                className="text-primary-600 hover:text-primary-700 font-medium"
              >
                Sign in here
              </button>
            </p>
            <p className="text-sm text-gray-600 mt-2">
              Want to see our plans?{' '}
              <button
                onClick={() => navigate('/pricing')}
                className="text-primary-600 hover:text-primary-700 font-medium"
              >
                View Pricing
              </button>
            </p>
          </div>
        )}
      </div>
    </div>
  )
}