import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    contentId: Number,
    theme: String,
    audioUrl: String
  }

  connect() {
    console.log('AudioPlayButtonController connected', {
      contentId: this.contentIdValue,
      theme: this.themeValue,
      audioUrl: this.audioUrlValue
    })
  }

  playContent(event) {
    event.preventDefault()
    
    console.log('AudioPlayButtonController: playContent called', {
      contentId: this.contentIdValue,
      theme: this.themeValue,
      audioUrl: this.audioUrlValue,
      element: this.element
    })
    
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
    
    console.log('AudioPlayButtonController: Dispatching content:play event', customEvent.detail)
    document.dispatchEvent(customEvent)
    console.log('AudioPlayButtonController: content:play event dispatched successfully')
  }
}