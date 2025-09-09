const CharCountMixin = {
  updateCharCount(input, display, threshold = null) {
    const currentLength = input.value.length
    display.textContent = currentLength
    
    if (threshold !== null) {
      if (currentLength >= threshold) {
        display.classList.remove("text-gray-400")
        display.classList.add("text-yellow-400")
      } else {
        display.classList.remove("text-yellow-400")
        display.classList.add("text-gray-400")
      }
    }
  },
  
  initCharCounter(input, display, threshold = null) {
    this.updateCharCount(input, display, threshold)
    
    input.addEventListener('input', () => {
      this.updateCharCount(input, display, threshold)
    })
  }
}

export default CharCountMixin