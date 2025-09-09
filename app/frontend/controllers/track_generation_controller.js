import { Controller } from "@hotwired/stimulus"
import { ErrorHandlingMixin } from "../mixins"

class TrackGenerationController extends Controller {
  static values = {
    trackCount: Number,
    url: String,
    confirmationMessage: String
  }

  connect() {
    this.element.addEventListener('click', this.handleClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('click', this.handleClick.bind(this))
  }

  async handleClick(event) {
    event.preventDefault()

    // Show confirmation dialog
    if (!this.showConfirmation()) {
      return
    }

    try {
      this.setLoadingState()
      await this.submitRequest()
    } catch (error) {
      this.handleError(error)
    } finally {
      this.resetState()
    }
  }

  showConfirmation() {
    return confirm(this.confirmationMessageValue)
  }

  setLoadingState() {
    this.element.disabled = true
    this.element.classList.add('opacity-50', 'cursor-wait')
    
    const originalText = this.element.innerHTML
    this.element.dataset.originalText = originalText
    this.element.innerHTML = '生成中...'
  }

  resetState() {
    this.element.disabled = false
    this.element.classList.remove('opacity-50', 'cursor-wait')
    
    if (this.element.dataset.originalText) {
      this.element.innerHTML = this.element.dataset.originalText
      delete this.element.dataset.originalText
    }
  }

  async submitRequest() {
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    
    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': token,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'text/html'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    // Redirect to the response URL (following Rails redirect)
    window.location.href = response.url
  }

  handleError(error) {
    const message = error.message.includes('HTTP') ? 
      'サーバーエラーが発生しました。しばらく後に再試行してください。' :
      'BGM生成に失敗しました。ネットワーク接続を確認してください。'
    
    ErrorHandlingMixin.handleError.call(this, new Error(message))
  }
}

Object.assign(TrackGenerationController.prototype, ErrorHandlingMixin)

export default TrackGenerationController