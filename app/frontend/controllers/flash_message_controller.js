import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }
  
  connect() {
    const delay = this.delayValue || 5000
    
    setTimeout(() => {
      this.fadeOut()
    }, delay)
  }
  
  fadeOut() {
    this.element.style.transition = "opacity 0.5s ease-out"
    this.element.style.opacity = "0"
    
    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
  
  close() {
    this.fadeOut()
  }
}