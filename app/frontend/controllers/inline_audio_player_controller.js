import { Controller } from "@hotwired/stimulus"

// Global store for managing multiple players
if (!window.inlineAudioPlayerStore) {
  window.inlineAudioPlayerStore = {
    currentPlayer: null
  }
}

export default class extends Controller {
  static values = {
    id: String,
    type: String,
    title: String,
    url: String
  }

  connect() {
    this.setupMediaController()
    this.setupEventListeners()
  }

  disconnect() {
    if (window.inlineAudioPlayerStore.currentPlayer === this) {
      window.inlineAudioPlayerStore.currentPlayer = null
    }
  }

  setupMediaController() {
    this.mediaController = this.element.querySelector("media-controller")
    this.audioElement = this.element.querySelector("audio")

    if (!this.mediaController || !this.audioElement) {
      console.error("Media controller or audio element not found", {
        id: this.idValue,
        type: this.typeValue
      })
      return
    }

    // Import media-chrome if not already loaded
    if (!customElements.get("media-controller")) {
      import("media-chrome").catch(error => {
        console.error("Failed to load media-chrome:", error)
      })
    }
  }

  setupEventListeners() {
    if (!this.mediaController) return

    // Listen for play event
    this.mediaController.addEventListener("play", this.handlePlay.bind(this))

    // Listen for pause event
    this.mediaController.addEventListener("pause", this.handlePause.bind(this))

    // Listen for error events
    this.audioElement.addEventListener("error", this.handleError.bind(this))
  }

  handlePlay(event) {
    // Pause any currently playing player
    if (window.inlineAudioPlayerStore.currentPlayer &&
        window.inlineAudioPlayerStore.currentPlayer !== this) {
      const otherAudio = window.inlineAudioPlayerStore.currentPlayer.audioElement
      if (otherAudio && !otherAudio.paused) {
        otherAudio.pause()
      }
    }

    // Set this as the current player
    window.inlineAudioPlayerStore.currentPlayer = this

    // Emit global event for compatibility with other components
    this.emitGlobalEvent("audio:play", {
      id: this.idValue,
      type: this.typeValue,
      title: this.titleValue,
      url: this.urlValue
    })
  }

  handlePause(event) {
    // Clear current player if it's this one
    if (window.inlineAudioPlayerStore.currentPlayer === this) {
      window.inlineAudioPlayerStore.currentPlayer = null
    }

    // Emit global event
    this.emitGlobalEvent("audio:pause", {
      id: this.idValue,
      type: this.typeValue
    })
  }

  handleError(event) {
    console.error("Audio playback error:", {
      id: this.idValue,
      type: this.typeValue,
      error: event
    })

    // Emit error event
    this.emitGlobalEvent("audio:error", {
      id: this.idValue,
      type: this.typeValue,
      error: event
    })
  }

  emitGlobalEvent(eventName, detail) {
    window.dispatchEvent(new CustomEvent(eventName, {
      detail: detail,
      bubbles: true
    }))
  }
}