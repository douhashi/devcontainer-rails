import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: Number }
  
  connect() {
    this.setupAutoClose()
  }
  
  setupAutoClose() {
    if (this.hasDurationValue && this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.close()
      }, this.durationValue)
    }
  }
  
  close() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
  
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}