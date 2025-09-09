import { Controller } from "@hotwired/stimulus"
import { CharCountMixin } from "../mixins"

class FormValidationController extends Controller {
  static targets = ["input", "charCount", "error", "promptInput", "promptCharCount"]
  
  connect() {
    if (this.hasInputTarget && this.hasCharCountTarget) {
      this.initCharCounter(this.inputTarget, this.charCountTarget, 240)
    }
    
    if (this.hasPromptInputTarget && this.hasPromptCharCountTarget) {
      this.initCharCounter(this.promptInputTarget, this.promptCharCountTarget, 900)
    }
  }
  
  updateCharCount() {
    if (this.hasInputTarget && this.hasCharCountTarget) {
      CharCountMixin.updateCharCount.call(this, this.inputTarget, this.charCountTarget, 240)
    }
  }
  
  updatePromptCharCount() {
    if (this.hasPromptInputTarget && this.hasPromptCharCountTarget) {
      CharCountMixin.updateCharCount.call(this, this.promptInputTarget, this.promptCharCountTarget, 900)
    }
  }
}

Object.assign(FormValidationController.prototype, CharCountMixin)

export default FormValidationController