import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  copy(event) {
    event.preventDefault()

    const content = this.contentValue

    if (navigator.clipboard && window.isSecureContext) {
      // Modern way - Clipboard API
      navigator.clipboard.writeText(content).then(() => {
        this.showSuccessMessage()
      }).catch(err => {
        console.error('Failed to copy: ', err)
        this.fallbackCopy(content)
      })
    } else {
      // Fallback for older browsers
      this.fallbackCopy(content)
    }
  }

  fallbackCopy(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text

    // Avoid scrolling to bottom
    textArea.style.top = "0"
    textArea.style.left = "0"
    textArea.style.position = "fixed"
    textArea.style.opacity = "0"

    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()

    try {
      const successful = document.execCommand('copy')
      if (successful) {
        this.showSuccessMessage()
      } else {
        this.showErrorMessage()
      }
    } catch (err) {
      console.error('Fallback: Oops, unable to copy', err)
      this.showErrorMessage()
    }

    document.body.removeChild(textArea)
  }

  showSuccessMessage() {
    // Show toast notification
    const toastEvent = new CustomEvent('toast:show', {
      detail: {
        message: 'クリップボードにコピーしました',
        type: 'success'
      }
    })
    window.dispatchEvent(toastEvent)

    // Visual feedback on button
    const originalText = this.element.innerHTML
    this.element.innerHTML = this.element.innerHTML.replace('コピー', 'コピー済み')
    this.element.classList.add('bg-green-600')
    this.element.classList.remove('bg-gray-700')

    setTimeout(() => {
      this.element.innerHTML = originalText
      this.element.classList.remove('bg-green-600')
      this.element.classList.add('bg-gray-700')
    }, 2000)
  }

  showErrorMessage() {
    const toastEvent = new CustomEvent('toast:show', {
      detail: {
        message: 'コピーに失敗しました',
        type: 'error'
      }
    })
    window.dispatchEvent(toastEvent)
  }
}