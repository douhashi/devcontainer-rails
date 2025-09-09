import { Controller } from "@hotwired/stimulus"
import { FadeOutMixin } from "../mixins"

class FlashMessageController extends Controller {
  static values = { duration: Number }
  
  connect() {
    if (!this.hasDurationValue) {
      this.durationValue = 5000
      this.hasDurationValue = true
    }
    this.setupAutoClose()
  }
  
  close() {
    this.cleanupTimeout()
    this.fadeOut(500)
  }
  
  disconnect() {
    this.cleanupTimeout()
  }
}

Object.assign(FlashMessageController.prototype, FadeOutMixin)

export default FlashMessageController