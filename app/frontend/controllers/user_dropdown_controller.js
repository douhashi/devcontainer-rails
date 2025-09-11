import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    this.isOpen = false
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }
  
  disconnect() {
    this.removeEventListeners()
  }
  
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }
  
  open() {
    this.isOpen = true
    this.menuTarget.classList.remove('hidden')
    this.updateAriaExpanded(true)
    this.addEventListeners()
    
    // Focus management for accessibility
    this.menuTarget.focus()
  }
  
  close() {
    this.isOpen = false
    this.menuTarget.classList.add('hidden')
    this.updateAriaExpanded(false)
    this.removeEventListeners()
  }
  
  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  closeOnEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
  
  // Private methods
  
  addEventListeners() {
    document.addEventListener('click', this.boundCloseOnOutsideClick)
    document.addEventListener('keydown', this.boundCloseOnEscape)
  }
  
  removeEventListeners() {
    document.removeEventListener('click', this.boundCloseOnOutsideClick)
    document.removeEventListener('keydown', this.boundCloseOnEscape)
  }
  
  updateAriaExpanded(isExpanded) {
    const trigger = this.element.querySelector('[role="button"]')
    if (trigger) {
      trigger.setAttribute('aria-expanded', isExpanded.toString())
    }
  }
}