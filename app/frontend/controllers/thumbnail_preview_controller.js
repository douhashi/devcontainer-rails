import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["originalImage", "thumbnailImage", "toggleButton", "loadingSpinner", "errorMessage"]
  static values = { contentId: Number }

  connect() {
    this.showingThumbnail = false
    this.thumbnailUrl = null
    this.originalUrl = null
  }

  async togglePreview() {
    if (!this.thumbnailUrl) {
      await this.loadPreview()
    }

    if (this.thumbnailUrl) {
      this.showingThumbnail = !this.showingThumbnail
      this.updateDisplay()
    }
  }

  async loadPreview() {
    this.showLoading()

    try {
      const response = await fetch(`/contents/${this.contentIdValue}/artwork/preview_thumbnail`)

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.error || 'Failed to load preview')
      }

      const data = await response.json()
      this.originalUrl = data.original_url
      this.thumbnailUrl = data.thumbnail_url

      // Preload thumbnail image
      await this.preloadImage(this.thumbnailUrl)

      this.hideLoading()
      this.showingThumbnail = true
      this.updateDisplay()
    } catch (error) {
      this.showError(error.message)
      this.hideLoading()
    }
  }

  preloadImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = resolve
      img.onerror = () => reject(new Error('Failed to load image'))
      img.src = url
    })
  }

  updateDisplay() {
    if (this.hasOriginalImageTarget && this.hasThumbnailImageTarget) {
      if (this.showingThumbnail) {
        this.originalImageTarget.classList.add('hidden')
        this.thumbnailImageTarget.classList.remove('hidden')
        this.thumbnailImageTarget.src = this.thumbnailUrl
        this.updateButtonText('オリジナルを表示')
      } else {
        this.originalImageTarget.classList.remove('hidden')
        this.thumbnailImageTarget.classList.add('hidden')
        this.updateButtonText('プレビューを表示')
      }
    }
  }

  updateButtonText(text) {
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = text
    }
  }

  showLoading() {
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.remove('hidden')
    }
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.disabled = true
    }
  }

  hideLoading() {
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.add('hidden')
    }
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.disabled = false
    }
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')

      // Hide error after 5 seconds
      setTimeout(() => {
        this.errorMessageTarget.classList.add('hidden')
      }, 5000)
    }
  }
}