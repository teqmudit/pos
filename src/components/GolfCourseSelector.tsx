import React, { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { MapPin, Check } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'
import toast from 'react-hot-toast'

interface GolfCourse {
  id: string
  name: string
  address: string
  phone_number?: string
  email?: string
  website?: string
  is_active: boolean
}

interface GolfCourseSelectorProps {
  selectedCourses: string[]
  onSelectionChange: (courseIds: string[]) => void
  className?: string
}

export default function GolfCourseSelector({ 
  selectedCourses, 
  onSelectionChange, 
  className = '' 
}: GolfCourseSelectorProps) {
  const [golfCourses, setGolfCourses] = useState<GolfCourse[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    fetchGolfCourses()
  }, [])

  const fetchGolfCourses = async () => {
    try {
      setLoading(true)

      const { data, error } = await supabase
        .from('golf_courses')
        .select('*')
        .eq('is_active', true)
        .order('name')

      if (error) throw error

      setGolfCourses(data || [])
    } catch (error) {
      console.error('Error fetching golf courses:', error)
      toast.error('Failed to load golf courses')
    } finally {
      setLoading(false)
    }
  }

  const handleCourseToggle = (courseId: string) => {
    const isSelected = selectedCourses.includes(courseId)
    
    if (isSelected) {
      onSelectionChange(selectedCourses.filter(id => id !== courseId))
    } else {
      onSelectionChange([...selectedCourses, courseId])
    }
  }

  const filteredCourses = golfCourses.filter(course =>
    course.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    course.address.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <LoadingSpinner size="md" />
      </div>
    )
  }

  return (
    <div className={className}>
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Select Golf Courses to Serve
        </label>
        <input
          type="text"
          placeholder="Search golf courses..."
          className="input"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        <p className="text-xs text-gray-500 mt-1">
          Choose which golf courses your kitchen will serve
        </p>
      </div>

      <div className="space-y-3 max-h-64 overflow-y-auto border border-gray-200 rounded-lg p-3">
        {filteredCourses.length > 0 ? (
          filteredCourses.map((course) => {
            const isSelected = selectedCourses.includes(course.id)
            
            return (
              <div
                key={course.id}
                className={`p-3 rounded-lg border-2 cursor-pointer transition-all ${
                  isSelected
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
                onClick={() => handleCourseToggle(course.id)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="font-medium text-gray-900">{course.name}</h4>
                      {isSelected && (
                        <Check className="h-4 w-4 text-primary-600" />
                      )}
                    </div>
                    <div className="flex items-start gap-1 text-sm text-gray-600">
                      <MapPin className="h-4 w-4 mt-0.5 flex-shrink-0" />
                      <span>{course.address}</span>
                    </div>
                    {course.phone_number && (
                      <p className="text-xs text-gray-500 mt-1">
                        {course.phone_number}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )
          })
        ) : (
          <div className="text-center py-6">
            <MapPin className="h-8 w-8 text-gray-400 mx-auto mb-2" />
            <p className="text-gray-600">
              {searchTerm ? 'No golf courses match your search' : 'No golf courses available'}
            </p>
          </div>
        )}
      </div>

      {selectedCourses.length > 0 && (
        <div className="mt-3 p-3 bg-primary-50 rounded-lg">
          <p className="text-sm font-medium text-primary-800">
            Selected: {selectedCourses.length} golf course{selectedCourses.length !== 1 ? 's' : ''}
          </p>
        </div>
      )}
    </div>
  )
}