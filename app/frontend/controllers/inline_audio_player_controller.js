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

  initialize() {
    // Bind methods to maintain correct context
    this.boundHandlePlay = this.handlePlay.bind(this)
    this.boundHandlePause = this.handlePause.bind(this)
    this.boundHandleError = this.handleError.bind(this)
    this.boundHandleMediaPlay = this.handleMediaPlay.bind(this)
    this.boundHandleMediaPause = this.handleMediaPause.bind(this)
  }

  connect() {
    this.setupMediaController()
    this.setupEventListeners()
  }

  disconnect() {
    // Clean up event listeners
    this.removeEventListeners()

    // Clear from global store if this is the current player
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
    if (!this.mediaController || !this.audioElement) return

    // Debug log
    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] Setting up event listeners", {
        id: this.idValue,
        type: this.typeValue
      })
    }

    // Listen for media-chrome events (primary)
    this.mediaController.addEventListener("media-play-request", this.boundHandleMediaPlay)
    this.mediaController.addEventListener("media-pause", this.boundHandleMediaPause)

    // Listen for audio element events (fallback)
    this.audioElement.addEventListener("play", this.boundHandlePlay)
    this.audioElement.addEventListener("pause", this.boundHandlePause)
    this.audioElement.addEventListener("error", this.boundHandleError)
  }

  removeEventListeners() {
    if (this.mediaController) {
      this.mediaController.removeEventListener("media-play-request", this.boundHandleMediaPlay)
      this.mediaController.removeEventListener("media-pause", this.boundHandleMediaPause)
    }

    if (this.audioElement) {
      this.audioElement.removeEventListener("play", this.boundHandlePlay)
      this.audioElement.removeEventListener("pause", this.boundHandlePause)
      this.audioElement.removeEventListener("error", this.boundHandleError)
    }
  }

  // Handle media-chrome play request event
  handleMediaPlay(event) {
    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] media-play-request event", {
        id: this.idValue,
        type: this.typeValue
      })
    }
    this.startPlayback()
  }

  // Handle media-chrome pause event
  handleMediaPause(event) {
    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] media-pause event", {
        id: this.idValue,
        type: this.typeValue
      })
    }
    this.stopPlayback()
  }

  // Handle audio element play event (fallback)
  handlePlay(event) {
    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] audio play event", {
        id: this.idValue,
        type: this.typeValue
      })
    }
    this.startPlayback()
  }

  // Handle audio element pause event (fallback)
  handlePause(event) {
    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] audio pause event", {
        id: this.idValue,
        type: this.typeValue
      })
    }
    this.stopPlayback()
  }

  startPlayback() {
    // Pause any currently playing player
    if (window.inlineAudioPlayerStore.currentPlayer &&
        window.inlineAudioPlayerStore.currentPlayer !== this) {
      const otherPlayer = window.inlineAudioPlayerStore.currentPlayer

      if (this.isDebugMode()) {
        console.log("[InlineAudioPlayer] Stopping other player", {
          currentId: this.idValue,
          otherId: otherPlayer.idValue
        })
      }

      // Try to pause via media controller first
      if (otherPlayer.mediaController && otherPlayer.mediaController.pause) {
        try {
          otherPlayer.mediaController.pause()
        } catch (e) {
          console.warn("[InlineAudioPlayer] Failed to pause via media controller", e)
        }
      }

      // Fallback to audio element
      if (otherPlayer.audioElement && !otherPlayer.audioElement.paused) {
        try {
          otherPlayer.audioElement.pause()
        } catch (e) {
          console.warn("[InlineAudioPlayer] Failed to pause via audio element", e)
        }
      }
    }

    // Set this as the current player
    window.inlineAudioPlayerStore.currentPlayer = this

    if (this.isDebugMode()) {
      console.log("[InlineAudioPlayer] Current player set", {
        id: this.idValue,
        type: this.typeValue
      })
    }

    // Emit global event for compatibility with other components
    this.emitGlobalEvent("audio:play", {
      id: this.idValue,
      type: this.typeValue,
      title: this.titleValue,
      url: this.urlValue
    })
  }

  stopPlayback() {
    // Clear current player if it's this one
    if (window.inlineAudioPlayerStore.currentPlayer === this) {
      window.inlineAudioPlayerStore.currentPlayer = null

      if (this.isDebugMode()) {
        console.log("[InlineAudioPlayer] Current player cleared", {
          id: this.idValue,
          type: this.typeValue
        })
      }
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

  isDebugMode() {
    // Enable debug logs in development environment
    return process.env.NODE_ENV === 'development' || window.location.hostname === 'localhost'
  }
}