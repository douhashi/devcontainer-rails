import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "charCount", "error"]
  
  connect() {
    this.updateCharCount()
  }
  
  updateCharCount() {
    const currentLength = this.inputTarget.value.length
    this.charCountTarget.textContent = currentLength
    
    if (currentLength >= 240) {
      this.charCountTarget.classList.remove("text-gray-400")
      this.charCountTarget.classList.add("text-yellow-400")
    } else {
      this.charCountTarget.classList.remove("text-yellow-400")
      this.charCountTarget.classList.add("text-gray-400")
    }
  }
}