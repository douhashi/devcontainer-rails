const FadeOutMixin = {
  setupAutoClose() {
    if (this.hasDurationValue && this.durationValue > 0) {
      this.autoCloseTimeout = setTimeout(() => {
        this.fadeOut()
      }, this.durationValue)
    }
  },
  
  fadeOut(duration = 300) {
    this.cleanupTimeout()
    this.element.classList.add("opacity-0", "transition-opacity")
    
    // Set transition duration directly via style instead of dynamic Tailwind class
    this.element.style.transitionDuration = `${duration}ms`
    
    this.fadeTimeout = setTimeout(() => {
      this.element.remove()
    }, duration)
  },
  
  cleanupTimeout() {
    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
      this.autoCloseTimeout = null
    }
    if (this.fadeTimeout) {
      clearTimeout(this.fadeTimeout)
      this.fadeTimeout = null
    }
  }
}

export default FadeOutMixin