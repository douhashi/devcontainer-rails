import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "resetButton"]

  connect() {
    try {
      this.validateDateRange()
    } catch (error) {
      console.error('TrackSearchController connect error:', error)
    }
  }

  validateDateRange() {
    try {
      if (this.hasStartDateTarget && this.hasEndDateTarget) {
        const startDate = this.startDateTarget.value
        const endDate = this.endDateTarget.value

        if (startDate && endDate) {
          // Ensure end date is not before start date
          if (new Date(endDate) < new Date(startDate)) {
            this.endDateTarget.value = startDate
          }
        }

        // Set min/max attributes for better UX
        if (startDate) {
          this.endDateTarget.min = startDate
        }
        if (endDate) {
          this.startDateTarget.max = endDate
        }
      }
    } catch (error) {
      console.error('TrackSearchController validateDateRange error:', error)
    }
  }

  // Called when start date changes
  startDateChanged() {
    try {
      this.validateDateRange()
    } catch (error) {
      console.error('TrackSearchController startDateChanged error:', error)
    }
  }

  // Called when end date changes
  endDateChanged() {
    try {
      this.validateDateRange()
    } catch (error) {
      console.error('TrackSearchController endDateChanged error:', error)
    }
  }

  // Reset form
  reset(event) {
    try {
      event.preventDefault()
      
      // Clear all form inputs
      this.element.querySelectorAll('input[type="text"], input[type="search"], input[type="date"]').forEach(input => {
        input.value = ''
      })
      
      // Reset select elements to first option
      this.element.querySelectorAll('select').forEach(select => {
        select.selectedIndex = 0
      })
      
      // Redirect to base path without search params
      if (this.hasResetButtonTarget) {
        window.location.href = this.resetButtonTarget.href
      }
    } catch (error) {
      console.error('TrackSearchController reset error:', error)
    }
  }
}