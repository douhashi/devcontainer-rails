import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "resetButton"]

  connect() {
    this.validateDateRange()
  }

  validateDateRange() {
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
  }

  // Called when start date changes
  startDateChanged() {
    this.validateDateRange()
  }

  // Called when end date changes
  endDateChanged() {
    this.validateDateRange()
  }

  // Reset form
  reset(event) {
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
  }
}