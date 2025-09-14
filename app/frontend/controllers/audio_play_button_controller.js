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
    
    // Dispatch unified custom event for audio player
    const customEvent = new CustomEvent("audio:play", {
      detail: audioData,
      bubbles: true
    })

    document.dispatchEvent(customEvent)
  }

  buildAudioData() {
    // Debug: Log the audio URL being retrieved
    console.debug('[AudioPlayButton] Building audio data:', {
      id: this.idValue,
      title: this.titleValue,
      audioUrl: this.audioUrlValue,
      type: this.typeValue
    })

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
        if (this.hasTrackListValue) {
          const parsedList = JSON.parse(this.trackListValue)
          // Map track list items to ensure they have audioUrl property
          // TODO: Future refactoring - unify to use only 'url' property once all components are migrated
          // Currently maintaining both 'url' and 'audioUrl' for backward compatibility
          baseData.trackList = parsedList.map(track => ({
            ...track,
            audioUrl: track.url || track.audioUrl  // Ensure audioUrl is present for compatibility
          }))
        } else {
          baseData.trackList = []
        }
        // Debug: Log parsed track list
        console.debug('[AudioPlayButton] Parsed track list:', baseData.trackList)
      } catch (e) {
        console.warn('[AudioPlayButton] Failed to parse track list, using single track:', e)
        baseData.trackList = [baseData]
      }
    } else {
      // For content type, create single-item track list
      baseData.trackList = [baseData]
    }

    // Debug: Log final audio data structure
    console.debug('[AudioPlayButton] Final audio data:', baseData)
    return baseData
  }

  // Legacy support methods (to be removed after migration)
  playContent(event) {
    this.play(event)
  }
}