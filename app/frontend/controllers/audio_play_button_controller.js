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
    console.log('AudioPlayButtonController connected (unified)', {
      id: this.idValue,
      title: this.titleValue,
      audioUrl: this.audioUrlValue,
      type: this.typeValue
    })
  }

  play(event) {
    event.preventDefault()
    
    console.log('AudioPlayButtonController: play called (unified)', {
      id: this.idValue,
      title: this.titleValue,
      audioUrl: this.audioUrlValue,
      type: this.typeValue,
      element: this.element
    })
    
    const audioData = this.buildAudioData()
    
    // Dispatch unified custom event for floating audio player
    const customEvent = new CustomEvent("audio:play", {
      detail: audioData,
      bubbles: true
    })
    
    console.log('AudioPlayButtonController: Dispatching audio:play event', customEvent.detail)
    document.dispatchEvent(customEvent)
    console.log('AudioPlayButtonController: audio:play event dispatched successfully')
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
        console.warn('AudioPlayButtonController: Failed to parse track list', e)
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
    console.warn('AudioPlayButtonController: playContent is deprecated, use play() instead')
    this.play(event)
  }
}