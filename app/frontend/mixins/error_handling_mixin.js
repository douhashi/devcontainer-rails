const ErrorHandlingMixin = {
  showError(message, options = {}) {
    const { autoRemove = true, timeout = 5000 } = options
    
    console.error('Error:', message)
    
    const errorElement = document.createElement('div')
    errorElement.className = 'error-message bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4'
    errorElement.textContent = message
    
    this.element.appendChild(errorElement)
    
    if (autoRemove) {
      setTimeout(() => {
        if (errorElement.parentNode) {
          errorElement.remove()
        }
      }, timeout)
    }
  },
  
  clearErrors() {
    const errorElements = this.element.querySelectorAll('.error-message')
    errorElements.forEach(element => element.remove())
  },
  
  handleError(error) {
    let message = 'An unexpected error occurred'
    
    if (error instanceof Error) {
      message = error.message
    } else if (typeof error === 'string') {
      message = error
    } else if (error && error.message) {
      message = error.message
    }
    
    this.showError(message)
  }
}

export default ErrorHandlingMixin