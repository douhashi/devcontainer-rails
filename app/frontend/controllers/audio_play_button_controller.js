import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    id: Number,
    title: String,
    audioUrl: String,
    type: String,
    contentId: Number,
    contentTitle: String,
    trackList: String
  }

  connect() {
    // AudioPlayButtonController connected
  }

  play(event) {
    event.preventDefault()

    const audioData = this.buildAudioData()
    
    // Dispatch unified custom event for floating audio player
    const customEvent = new CustomEvent("audio:play", {
      detail: audioData,
      bubbles: true
    })

    document.dispatchEvent(customEvent)
  }

  buildAudioData() {
    const baseData = {
      id: this.idValue,
      title: this.titleValue || "Untitled",
      audioUrl: this.audioUrlValue,
      type: this.typeValue
    }

    // Add track-specific data if available
    if (this.typeValue === "track" && this.hasContentIdValue) {
      baseData.contentId = this.contentIdValue
      baseData.contentTitle = this.contentTitleValue || ""
      
      // Parse track list if available
      try {
        baseData.trackList = this.hasTrackListValue ? JSON.parse(this.trackListValue) : []
      } catch (e) {
        baseData.trackList = [baseData]
      }
    } else {
      // For content type, create single-item track list
      baseData.trackList = [baseData]
    }

    return baseData
  }

  // Legacy support methods (to be removed after migration)
  playContent(event) {
    this.play(event)
  }
}