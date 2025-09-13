import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { contentId: Number }

  generate(event) {
    // Optional: Add any client-side handling for audio generation
    // The actual generation is handled server-side via the form submission
    
    console.debug(`Generating audio for content ${this.contentIdValue}`)
    
    // Disable the button to prevent double-submission
    const button = event.target
    button.disabled = true
    
    // Re-enable after a delay (the page will likely redirect before this)
    setTimeout(() => {
      button.disabled = false
    }, 3000)
  }
}