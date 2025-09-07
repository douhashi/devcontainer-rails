import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterButton"]
  static values = { selected: String }

  connect() {
    this.updateActiveButton(this.selectedValue)
  }

  filter(event) {
    const status = event.currentTarget.dataset.status
    this.selectedValue = status
    this.updateActiveButton(status)
    this.filterContents(status)
  }

  updateActiveButton(activeStatus) {
    this.filterButtonTargets.forEach(button => {
      const status = button.dataset.status
      const isActive = status === activeStatus

      if (isActive) {
        button.classList.remove("bg-gray-200", "text-gray-700", "border-gray-300", "hover:bg-gray-300")
        button.classList.add("bg-blue-500", "text-white", "border-blue-500")
      } else {
        button.classList.remove("bg-blue-500", "text-white", "border-blue-500")
        button.classList.add("bg-gray-200", "text-gray-700", "border-gray-300", "hover:bg-gray-300")
      }
    })
  }

  filterContents(status) {
    const contentCards = document.querySelectorAll('[data-content-id]')
    
    contentCards.forEach(card => {
      const cardStatus = card.dataset.completionStatus
      const shouldShow = status === 'all' || cardStatus === status

      if (shouldShow) {
        card.style.display = ''
        card.classList.remove('hidden')
      } else {
        card.style.display = 'none'
        card.classList.add('hidden')
      }
    })

    this.updateVisibleCount(status)
  }

  updateVisibleCount(status) {
    const totalCards = document.querySelectorAll('[data-content-id]').length
    let visibleCards = totalCards

    if (status !== 'all') {
      visibleCards = document.querySelectorAll(`[data-content-id][data-completion-status="${status}"]:not(.hidden)`).length
    }

    // Dispatch custom event for other components to listen to
    this.dispatch("filtered", { 
      detail: { 
        status: status, 
        visible: visibleCards, 
        total: totalCards 
      } 
    })
  }
}