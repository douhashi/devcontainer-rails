import { Controller } from "@hotwired/stimulus"
import { FadeOutMixin } from "../mixins"

class ToastController extends Controller {
  static values = { duration: Number }
  
  connect() {
    this.setupAutoClose()
  }
  
  close() {
    this.cleanupTimeout()
    this.fadeOut()
  }
  
  disconnect() {
    this.cleanupTimeout()
  }
}

Object.assign(ToastController.prototype, FadeOutMixin)

export default ToastController