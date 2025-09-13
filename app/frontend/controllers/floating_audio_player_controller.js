import { Controller } from "@hotwired/stimulus"
import { PlaybackController } from "./playback_controller"

export default class extends Controller {
  static targets = ["audio", "trackTitle", "playButton", "playIcon", "pauseIcon"]

  connect() {
    this.initializePlayer()
    this.setupEventListeners()
    this.trackList = []
    this.currentTrackIndex = 0
    this.playbackController = null
  }

  disconnect() {
    if (this.playbackController) {
      this.playbackController.cleanup()
      this.playbackController = null
    }
    if (this.audioElement) {
      // Remove event listeners from audio element only
      this.audioElement.removeEventListener('play', this.handleMediaPlay)
      this.audioElement.removeEventListener('pause', this.handleMediaPause)
      this.audioElement.removeEventListener('ended', this.handleMediaEnded)
      this.audioElement = null
    }
    this.player = null
    this.removeEventListeners()
  }

  initializePlayer() {
    if (!this.audioTarget) {
      console.error('[FloatingAudioPlayer] Audio target not found')
      return
    }

    // Store reference to media-controller element
    this.player = this.audioTarget

    // Get the audio element inside the media-controller
    this.audioElement = this.player.querySelector('audio[slot="media"]')
    if (!this.audioElement) {
      console.error('[FloatingAudioPlayer] Audio element not found in media-controller')
      // Try to find audio element directly as fallback
      this.audioElement = this.element.querySelector('audio')
      if (!this.audioElement) {
        console.error('[FloatingAudioPlayer] No audio element found at all')
        return
      }
    }
    console.debug('[FloatingAudioPlayer] Audio element initialized:', this.audioElement)

    // Initialize PlaybackController
    this.playbackController = new PlaybackController(this.audioElement)

    // Bind event handlers with debounce protection
    this.isProcessingEvent = false
    this.eventDebounceTimeout = null

    this.handleMediaPlay = () => {
      // Prevent duplicate event processing
      if (this.isProcessingEvent) return
      this.isProcessingEvent = true

      // Player started playing
      this.updatePlayButton(true)
      this.stopOtherPlayers()

      // Reset flag after a short delay
      clearTimeout(this.eventDebounceTimeout)
      this.eventDebounceTimeout = setTimeout(() => {
        this.isProcessingEvent = false
      }, 100)
    }

    this.handleMediaPause = () => {
      // Prevent duplicate event processing
      if (this.isProcessingEvent) return
      this.isProcessingEvent = true

      // Player paused
      this.updatePlayButton(false)

      // Reset flag after a short delay
      clearTimeout(this.eventDebounceTimeout)
      this.eventDebounceTimeout = setTimeout(() => {
        this.isProcessingEvent = false
      }, 100)
    }

    this.handleMediaEnded = () => {
      // Player ended
      this.next()
    }

    // Add event listeners to audio element only (not media-controller)
    // This prevents duplicate events from being fired
    this.audioElement.addEventListener('play', this.handleMediaPlay)
    this.audioElement.addEventListener('pause', this.handleMediaPause)
    this.audioElement.addEventListener('ended', this.handleMediaEnded)
    
    // Set default volume on audio element
    if (this.audioElement) {
      this.audioElement.volume = 0.8
    }
  }

  setupEventListeners() {
    this.audioPlayHandler = this.handleAudioPlayEvent.bind(this)
    this.playHandler = this.handlePlayEvent.bind(this)
    this.contentPlayHandler = this.handleContentPlayEvent.bind(this)
    
    // New unified event listener
    document.addEventListener("audio:play", this.audioPlayHandler)
    
    // Legacy event listeners (for backward compatibility during transition)
    document.addEventListener("track:play", this.playHandler)
    document.addEventListener("content:play", this.contentPlayHandler)
  }

  removeEventListeners() {
    if (this.audioPlayHandler) {
      document.removeEventListener("audio:play", this.audioPlayHandler)
    }
    if (this.playHandler) {
      document.removeEventListener("track:play", this.playHandler)
    }
    if (this.contentPlayHandler) {
      document.removeEventListener("content:play", this.contentPlayHandler)
    }
  }

  handlePlayEvent(event) {
    const button = event.target.closest('button') || event.target
    const trackData = {
      id: parseInt(button.dataset.trackId),
      title: button.dataset.trackTitle,
      url: button.dataset.trackUrl,
      contentId: parseInt(button.dataset.contentId),
      contentTitle: button.dataset.contentTitle
    }
    
    // Parse track list
    try {
      this.trackList = JSON.parse(button.dataset.trackList || "[]")
    } catch (e) {
      this.trackList = [trackData]
    }
    
    // Find current track index
    this.currentTrackIndex = this.trackList.findIndex(t => t.id === trackData.id)
    if (this.currentTrackIndex === -1) {
      this.currentTrackIndex = 0
    }
    
    this.playTrack(trackData)
    this.show()
  }

  handleContentPlayEvent(event) {
    const eventDetail = event.detail
    
    const trackData = {
      id: `content-${eventDetail.contentId}`,
      title: eventDetail.theme || "Untitled",
      url: eventDetail.audioUrl,
      contentId: eventDetail.contentId,
      contentTitle: eventDetail.theme || "Untitled"
    }


    // Create single track for content audio
    this.trackList = [trackData]
    this.currentTrackIndex = 0
    
    this.playTrack(trackData)
    this.show()
  }

  handleAudioPlayEvent(event) {
    const eventDetail = event.detail
    console.debug('[FloatingAudioPlayer] Received audio:play event:', eventDetail)

    // Convert unified data format to internal track format
    const trackData = {
      id: eventDetail.type === "track" ? eventDetail.id : `content-${eventDetail.id}`,
      title: eventDetail.title,
      url: eventDetail.audioUrl,  // Map audioUrl to url
      contentId: eventDetail.contentId || eventDetail.id,
      contentTitle: eventDetail.contentTitle || eventDetail.title
    }
    console.debug('[FloatingAudioPlayer] Converted track data:', trackData)


    // Use track list if available (for tracks), otherwise create single item list
    if (eventDetail.trackList && eventDetail.trackList.length > 0) {
      // TODO: Future refactoring - unify to use only 'url' property once all components are migrated
      // Currently supporting both 'audioUrl' and 'url' for backward compatibility
      this.trackList = eventDetail.trackList.map(track => ({
        id: track.id,
        title: track.title,
        url: track.audioUrl || track.url  // Prioritize audioUrl over url for compatibility
      }))
      console.debug('[FloatingAudioPlayer] Track list:', this.trackList)
      // Find current track index
      this.currentTrackIndex = this.trackList.findIndex(t => t.id === eventDetail.id)
      if (this.currentTrackIndex === -1) {
        this.currentTrackIndex = 0
      }
    } else {
      // Single track for content
      this.trackList = [trackData]
      this.currentTrackIndex = 0
    }

    this.playTrack(trackData)
    this.show()
  }

  play(event) {
    event.preventDefault()
    const button = event.currentTarget
    
    // Dispatch custom event for floating player
    const customEvent = new CustomEvent("track:play", {
      detail: button.dataset,
      bubbles: true
    })
    button.dispatchEvent(customEvent)
  }

  async playTrack(trackData) {
    if (!trackData) {
      console.error('[FloatingAudioPlayer] No track data provided')
      return
    }

    console.debug('[FloatingAudioPlayer] Playing track:', trackData)

    // Prevent concurrent playTrack calls
    if (this.isLoadingTrack) {
      console.debug('[FloatingAudioPlayer] Already loading a track, skipping...')
      return
    }
    this.isLoadingTrack = true

    try {
      this.trackTitleTarget.textContent = trackData.title || "Untitled"

      // Ensure audio element and playback controller are available
      if (!this.audioElement || !this.playbackController) {
        console.error('[FloatingAudioPlayer] Audio element or playback controller not available')
        return
      }

      // Validate URL
      if (!trackData.url) {
        console.error('[FloatingAudioPlayer] No audio URL provided in track data:', trackData)
        return
      }

      console.debug('[FloatingAudioPlayer] Setting audio source:', trackData.url)

      // Set new audio source
      this.audioElement.src = trackData.url

      // Set CORS attribute for cross-origin audio
      this.audioElement.crossOrigin = 'anonymous'

      // Check if browser can play the audio format
      const canPlayType = this.audioElement.canPlayType('audio/mpeg')
      console.debug('[FloatingAudioPlayer] Can play audio/mpeg:', canPlayType)

      // Load the audio explicitly
      this.audioElement.load()
      console.debug('[FloatingAudioPlayer] Audio loaded')

      // Update global state
      if (window.floatingPlayerStore) {
        window.floatingPlayerStore.currentTrack = trackData
      }

      // Play the new track using PlaybackController for safe playback
      console.debug('[FloatingAudioPlayer] Attempting to play audio using PlaybackController...')
      await this.playbackController.safePlay(true)

      console.debug('[FloatingAudioPlayer] Audio playback started successfully')
      this.updateAllPlayButtons(trackData.id)

    } catch (error) {
      // Enhanced error handling with specific AbortError treatment
      if (error.name === 'AbortError') {
        console.debug('[FloatingAudioPlayer] Playback was safely aborted:', error.message)
        // AbortError は正常な中断なので、ユーザーには表示しない
      } else {
        // Log all other errors with details
        console.error('[FloatingAudioPlayer] Failed to play audio:', {
          error: error,
          errorName: error.name,
          errorMessage: error.message,
          audioSrc: this.audioElement?.src,
          trackData: trackData
        })

        // Handle specific error types
        if (error.name === 'NotAllowedError') {
          console.error('[FloatingAudioPlayer] Playback not allowed. User interaction may be required.')
        } else if (error.name === 'NotSupportedError') {
          console.error('[FloatingAudioPlayer] Media format not supported.')
        }
      }
    } finally {
      this.isLoadingTrack = false
    }
  }

  previous() {
    if (this.trackList.length === 0) return
    
    this.currentTrackIndex = (this.currentTrackIndex - 1 + this.trackList.length) % this.trackList.length
    this.playTrack(this.trackList[this.currentTrackIndex])
  }

  next() {
    if (this.trackList.length === 0) return
    
    this.currentTrackIndex = (this.currentTrackIndex + 1) % this.trackList.length
    this.playTrack(this.trackList[this.currentTrackIndex])
  }

  async togglePlay() {
    // Prevent simultaneous play/pause calls using PlaybackController's busy check
    if (!this.playbackController || this.playbackController.isBusy()) {
      console.debug('[FloatingAudioPlayer] Toggle play blocked: playback controller busy')
      return
    }

    if (!this.audioElement) {
      console.error('[FloatingAudioPlayer] No audio element available for toggle')
      return
    }

    try {
      // Check if media is playing using audio element's paused property
      if (!this.audioElement.paused) {
        // Currently playing - pause it
        console.debug('[FloatingAudioPlayer] Toggling to pause')
        this.audioElement.pause()
      } else {
        // Currently paused - play it using PlaybackController for safe playback
        console.debug('[FloatingAudioPlayer] Toggling to play')
        await this.playbackController.safePlay(false) // Don't pause before playing since we're already paused
      }
    } catch (error) {
      if (error.name === 'AbortError') {
        console.debug('[FloatingAudioPlayer] Toggle play was safely aborted:', error.message)
      } else {
        console.error('[FloatingAudioPlayer] Failed to toggle playback:', {
          errorName: error.name,
          errorMessage: error.message,
          audioSrc: this.audioElement.src
        })
      }
    }
  }

  close() {
    // Stop playback using audio element
    if (this.audioElement) {
      this.audioElement.pause()
      this.audioElement.currentTime = 0
    }
    this.hide()
    this.updateAllPlayButtons(null)
    
    // Clear global state
    if (window.floatingPlayerStore) {
      window.floatingPlayerStore.currentTrack = null
    }
  }

  show() {
    this.element.classList.remove("hidden")
    this.element.classList.remove("translate-y-full")
    // Force reflow to ensure the transition works
    this.element.offsetHeight
    this.element.classList.add("translate-y-0")
  }

  hide() {
    this.element.classList.remove("translate-y-0")
    this.element.classList.add("translate-y-full")
    // Hide after animation completes
    setTimeout(() => {
      if (this.element.classList.contains("translate-y-full")) {
        this.element.classList.add("hidden")
      }
    }, 300)
  }

  updatePlayButton(isPlaying) {
    if (isPlaying) {
      this.playIconTarget.classList.add("hidden")
      this.pauseIconTarget.classList.remove("hidden")
    } else {
      this.playIconTarget.classList.remove("hidden")
      this.pauseIconTarget.classList.add("hidden")
    }
  }

  updateAllPlayButtons(currentTrackId) {
    // Update all play buttons on the page
    document.querySelectorAll("[id^='audio-play-button-track-']").forEach(button => {
      // buttonのIDからtrackIdを抽出 (例: "audio-play-button-track-123" -> 123)
      const buttonId = button.id
      const trackId = parseInt(buttonId.replace('audio-play-button-track-', ''))
      const isPlaying = trackId === currentTrackId
      button.dataset.playing = isPlaying
      
      // Update button visual state
      if (isPlaying) {
        // 再生中のボタンにはbg-blue-600を追加
        button.classList.add("bg-blue-600")
      } else {
        // 再生中でないボタンからはbg-blue-600を削除
        button.classList.remove("bg-blue-600")
      }
    })
  }

  stopOtherPlayers() {
    // Stop any other audio players on the page
    document.querySelectorAll("audio").forEach(audio => {
      if (audio !== this.audioTarget && !audio.paused) {
        audio.pause()
      }
    })
  }
}