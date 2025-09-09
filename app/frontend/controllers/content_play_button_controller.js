import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    contentId: Number,
    theme: String,
    audioUrl: String
  }

  playContent(event) {
    event.preventDefault()
    
    const theme = this.themeValue || "Untitled"
    
    // Dispatch custom event for floating audio player
    const customEvent = new CustomEvent("content:play", {
      detail: {
        contentId: this.contentIdValue,
        theme: theme,
        audioUrl: this.audioUrlValue
      },
      bubbles: true
    })
    
    document.dispatchEvent(customEvent)
  }
}