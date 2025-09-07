import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "charCount", "error", "promptInput", "promptCharCount"]
  
  connect() {
    this.updateCharCount()
    this.updatePromptCharCount()
  }
  
  updateCharCount() {
    if (!this.hasInputTarget) return
    
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
  
  updatePromptCharCount() {
    if (!this.hasPromptInputTarget) return
    
    const currentLength = this.promptInputTarget.value.length
    this.promptCharCountTarget.textContent = currentLength
    
    if (currentLength >= 900) {
      this.promptCharCountTarget.classList.remove("text-gray-400")
      this.promptCharCountTarget.classList.add("text-yellow-400")
    } else {
      this.promptCharCountTarget.classList.remove("text-yellow-400")
      this.promptCharCountTarget.classList.add("text-gray-400")
    }
  }
}