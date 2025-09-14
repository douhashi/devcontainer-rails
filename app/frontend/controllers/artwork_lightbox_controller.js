import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lightbox",
    "counter",
    "currentNumber",
    "currentImage",
    "imageLabel",
    "imageDimensions",
    "imageSize",
    "imageFormat",
    "metadata",
    "imageContainer"
  ]

  static values = {
    images: Array,
    currentIndex: Number
  }

  connect() {
    this.setupSwipeDetection()
    this.setupFocusTrap()

    if (this.hasImagesValue && this.imagesValue.length > 0) {
      this.updateDisplay()
    }
  }

  disconnect() {
    this.removeFocusTrap()
  }

  open(event) {
    if (event) {
      event.preventDefault()

      const index = parseInt(event.currentTarget.dataset.imageIndex || 0)
      this.currentIndexValue = index
    }

    this.lightboxTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.lightboxTarget.classList.add("opacity-100")
      this.lightboxTarget.classList.remove("opacity-0")
    })

    this.updateDisplay()
    this.trapFocus()

    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    this.lightboxTarget.classList.add("opacity-0")
    this.lightboxTarget.classList.remove("opacity-100")

    setTimeout(() => {
      this.lightboxTarget.classList.add("hidden")
    }, 300)

    this.releaseFocus()

    document.body.style.overflow = ""
  }

  closeOnBackdrop(event) {
    if (event.target === this.lightboxTarget ||
        event.target.closest('[data-artwork-lightbox-target="imageContainer"]') === null) {
      this.close()
    }
  }

  next(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.imagesValue.length === 0) return

    this.currentIndexValue = (this.currentIndexValue + 1) % this.imagesValue.length
    this.updateDisplay()
  }

  previous(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.imagesValue.length === 0) return

    this.currentIndexValue = (this.currentIndexValue - 1 + this.imagesValue.length) % this.imagesValue.length
    this.updateDisplay()
  }

  handleKeydown(event) {
    if (!this.lightboxTarget.classList.contains("hidden")) {
      switch (event.key) {
        case "Escape":
          this.close()
          break
        case "ArrowLeft":
          this.previous()
          break
        case "ArrowRight":
          this.next()
          break
      }
    }
  }

  updateDisplay() {
    if (!this.hasImagesValue || this.imagesValue.length === 0) return

    const currentImage = this.imagesValue[this.currentIndexValue]
    if (!currentImage) return

    // 画像を更新
    this.currentImageTarget.src = currentImage.url
    this.currentImageTarget.alt = `${currentImage.label}画像`

    // カウンターを更新
    this.currentNumberTarget.textContent = this.currentIndexValue + 1

    // メタデータを更新
    this.imageLabelTarget.textContent = currentImage.label || ""

    if (currentImage.metadata) {
      const metadata = currentImage.metadata

      if (metadata.width && metadata.height) {
        this.imageDimensionsTarget.textContent = `${metadata.width}x${metadata.height}`
      }

      if (metadata.size) {
        this.imageSizeTarget.textContent = this.formatFileSize(metadata.size)
      }

      if (metadata.format) {
        this.imageFormatTarget.textContent = metadata.format
      }
    }
  }

  formatFileSize(sizeInBytes) {
    if (!sizeInBytes) return "N/A"

    const size = typeof sizeInBytes === "string" ? parseInt(sizeInBytes) : sizeInBytes

    if (size < 1024) {
      return `${size}B`
    } else if (size < 1024 * 1024) {
      return `${(size / 1024).toFixed(1)}KB`
    } else {
      return `${(size / (1024 * 1024)).toFixed(1)}MB`
    }
  }

  setupSwipeDetection() {
    let touchStartX = 0
    let touchEndX = 0

    this.lightboxTarget.addEventListener("touchstart", (e) => {
      touchStartX = e.changedTouches[0].screenX
    })

    this.lightboxTarget.addEventListener("touchend", (e) => {
      touchEndX = e.changedTouches[0].screenX
      this.handleSwipe(touchStartX, touchEndX)
    })
  }

  handleSwipe(startX, endX) {
    const threshold = 50
    const diff = startX - endX

    if (Math.abs(diff) > threshold) {
      if (diff > 0) {
        this.next()
      } else {
        this.previous()
      }
    }
  }

  setupFocusTrap() {
    this.focusableElements = this.lightboxTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )

    this.firstFocusableElement = this.focusableElements[0]
    this.lastFocusableElement = this.focusableElements[this.focusableElements.length - 1]

    this.handleFocusTrap = (e) => {
      if (e.key === "Tab") {
        if (e.shiftKey) {
          if (document.activeElement === this.firstFocusableElement) {
            e.preventDefault()
            this.lastFocusableElement.focus()
          }
        } else {
          if (document.activeElement === this.lastFocusableElement) {
            e.preventDefault()
            this.firstFocusableElement.focus()
          }
        }
      }
    }
  }

  trapFocus() {
    this.previousActiveElement = document.activeElement

    if (this.firstFocusableElement) {
      this.firstFocusableElement.focus()
    }

    document.addEventListener("keydown", this.handleFocusTrap)
  }

  releaseFocus() {
    document.removeEventListener("keydown", this.handleFocusTrap)

    if (this.previousActiveElement) {
      this.previousActiveElement.focus()
    }
  }

  removeFocusTrap() {
    if (this.handleFocusTrap) {
      document.removeEventListener("keydown", this.handleFocusTrap)
    }
  }
}