import { Controller } from "@hotwired/stimulus"
import { PlaybackController } from "./playback_controller"
import { AudioStateManager } from "../lib/audio_state_manager"
import { PlaybackQueue } from "../lib/playback_queue"
import { AudioEventManager } from "../lib/audio_event_manager"

export default class extends Controller {
  static targets = ["audio", "trackTitle", "playButton", "playIcon", "pauseIcon"]

  async connect() {
    console.debug('[FloatingAudioPlayer] Controller connecting...')

    // Initialize state management
    this.stateManager = AudioStateManager.getInstance()
    this.playbackQueue = new PlaybackQueue()
    this.eventManager = new AudioEventManager()

    // Initialize properties
    this.trackList = []
    this.currentTrackIndex = 0
    this.playbackController = null

    // Wait for media-controller custom element to be defined
    await this.waitForMediaController()

    // Initialize player components
    this.initializePlayer()
    this.setupEventListeners()
    this.setupStateListeners()

    console.debug('[FloatingAudioPlayer] Controller connected successfully')
  }

  async waitForMediaController() {
    // Check if media-controller custom element is already defined
    if (customElements.get('media-controller')) {
      console.debug('[FloatingAudioPlayer] media-controller already defined')
      return
    }

    console.debug('[FloatingAudioPlayer] Waiting for media-controller to be defined...')

    try {
      // Wait for media-controller custom element to be defined with timeout
      await Promise.race([
        customElements.whenDefined('media-controller'),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('media-controller definition timeout')), 5000)
        )
      ])

      console.debug('[FloatingAudioPlayer] media-controller defined successfully')
    } catch (error) {
      console.error('[FloatingAudioPlayer] Failed to wait for media-controller:', error)
    }
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
    this.removeStateListeners()
    this.eventManager.cleanup()
    this.playbackQueue.clear()
  }

  initializePlayer() {
    console.debug('[FloatingAudioPlayer] Starting player initialization...')

    // Check for audioTarget (media-controller)
    if (!this.hasAudioTarget) {
      console.error('[FloatingAudioPlayer] Audio target (media-controller) not found')
      console.debug('[FloatingAudioPlayer] Available targets:', this.targets)
      console.debug('[FloatingAudioPlayer] DOM structure:', this.element.innerHTML.substring(0, 500))
      return
    }

    // Store reference to media-controller element
    this.player = this.audioTarget
    console.debug('[FloatingAudioPlayer] Media-controller element:', this.player)
    console.debug('[FloatingAudioPlayer] Media-controller tagName:', this.player?.tagName)
    console.debug('[FloatingAudioPlayer] Media-controller hasMedia:', this.player?.hasMedia)

    // Ensure media-controller is fully initialized
    if (!this.ensureMediaControllerReady()) {
      console.error('[FloatingAudioPlayer] Media-controller not ready after initialization')
      return
    }

    // Get the audio element inside the media-controller
    this.audioElement = this.findAudioElement()
    if (!this.audioElement) {
      console.error('[FloatingAudioPlayer] Failed to find audio element after multiple attempts')
      return
    }

    console.debug('[FloatingAudioPlayer] Audio element found:', this.audioElement)
    console.debug('[FloatingAudioPlayer] Audio element src:', this.audioElement.src)
    console.debug('[FloatingAudioPlayer] Audio element readyState:', this.audioElement.readyState)

    // Initialize PlaybackController
    try {
      this.playbackController = new PlaybackController(this.audioElement)
      console.debug('[FloatingAudioPlayer] PlaybackController initialized successfully')
    } catch (error) {
      console.error('[FloatingAudioPlayer] Failed to initialize PlaybackController:', error)
      return
    }

    // Bind event handlers with debounce protection
    this.isProcessingEvent = false
    this.eventDebounceTimeout = null

    this.handleMediaPlay = () => {
      // Prevent duplicate event processing
      if (this.isProcessingEvent) return
      this.isProcessingEvent = true

      // Update state manager
      this.stateManager.setState(AudioStateManager.STATES.PLAYING)

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

      // Update state manager
      this.stateManager.setState(AudioStateManager.STATES.PAUSED)

      // Player paused
      this.updatePlayButton(false)

      // Reset flag after a short delay
      clearTimeout(this.eventDebounceTimeout)
      this.eventDebounceTimeout = setTimeout(() => {
        this.isProcessingEvent = false
      }, 100)
    }

    this.handleMediaEnded = () => {
      // Update state manager
      this.stateManager.setState(AudioStateManager.STATES.STOPPED)

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

    console.debug('[FloatingAudioPlayer] Player initialization completed')
  }

  ensureMediaControllerReady() {
    if (!this.player) return false

    // Check if media-controller is properly connected to the DOM
    if (!this.player.isConnected) {
      console.warn('[FloatingAudioPlayer] Media-controller not connected to DOM')
      return false
    }

    // For media-chrome v4+, check if the element is ready
    // The media-controller should have its shadow DOM attached
    if (this.player.shadowRoot) {
      console.debug('[FloatingAudioPlayer] Media-controller has shadow DOM attached')
    }

    return true
  }

  findAudioElement() {
    let audioElement = null
    let attempts = 0
    const maxAttempts = 3

    while (!audioElement && attempts < maxAttempts) {
      attempts++
      console.debug(`[FloatingAudioPlayer] Attempting to find audio element (attempt ${attempts}/${maxAttempts})`)

      // First try: Look for audio element with slot="media" inside media-controller
      audioElement = this.player?.querySelector('audio[slot="media"]')
      if (audioElement) {
        console.debug('[FloatingAudioPlayer] Found audio element with slot="media"')
        break
      }

      // Second try: Look for any audio element inside media-controller
      audioElement = this.player?.querySelector('audio')
      if (audioElement) {
        console.debug('[FloatingAudioPlayer] Found audio element without slot attribute')
        // Ensure it has the correct slot attribute
        audioElement.setAttribute('slot', 'media')
        break
      }

      // Third try: Look for audio element in the entire component
      audioElement = this.element.querySelector('audio')
      if (audioElement) {
        console.debug('[FloatingAudioPlayer] Found audio element in component root')
        // Move it to the correct location if needed
        if (!audioElement.hasAttribute('slot')) {
          audioElement.setAttribute('slot', 'media')
        }
        break
      }

      // Wait a bit before next attempt
      if (attempts < maxAttempts) {
        console.debug('[FloatingAudioPlayer] Audio element not found, waiting before retry...')
        // Use a synchronous wait for simplicity in initialization
        const waitTime = 100 * attempts // Increasing wait time
        const start = Date.now()
        while (Date.now() - start < waitTime) {
          // Busy wait
        }
      }
    }

    return audioElement
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

  setupStateListeners() {
    // Listen for state changes
    this.stateChangeHandler = (event) => {
      const { newState } = event.detail

      // Update UI based on state
      switch (newState) {
        case AudioStateManager.STATES.PLAYING:
          this.updatePlayButton(true)
          break
        case AudioStateManager.STATES.PAUSED:
        case AudioStateManager.STATES.STOPPED:
          this.updatePlayButton(false)
          break
      }
    }

    this.stateManager.addEventListener('statechange', this.stateChangeHandler)

    // Listen for track changes
    this.trackChangeHandler = (event) => {
      const { newTrack } = event.detail
      if (newTrack) {
        this.updateAllPlayButtons(newTrack.id)
      } else {
        this.updateAllPlayButtons(null)
      }
    }

    this.stateManager.addEventListener('trackchange', this.trackChangeHandler)
  }

  removeStateListeners() {
    if (this.stateChangeHandler) {
      this.stateManager.removeEventListener('statechange', this.stateChangeHandler)
    }
    if (this.trackChangeHandler) {
      this.stateManager.removeEventListener('trackchange', this.trackChangeHandler)
    }
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

    // Add to playback queue
    const playbackItem = {
      id: trackData.id,
      priority: PlaybackQueue.PRIORITY.HIGH,
      execute: async (signal) => {
        // Update state to loading
        this.stateManager.setState(AudioStateManager.STATES.LOADING)

        // Update current track in state manager
        this.stateManager.setCurrentTrack(trackData)

        this.trackTitleTarget.textContent = trackData.title || "Untitled"

        // Ensure audio element and playback controller are available
        if (!this.audioElement) {
          console.error('[FloatingAudioPlayer] Audio element not available during playback')
          console.debug('[FloatingAudioPlayer] Player state:', {
            hasPlayer: !!this.player,
            playerConnected: this.player?.isConnected,
            hasAudioTarget: this.hasAudioTarget
          })
          // Try to reinitialize
          this.initializePlayer()
          if (!this.audioElement) {
            throw new Error('Audio element not available after reinitialization')
          }
        }

        if (!this.playbackController) {
          console.error('[FloatingAudioPlayer] PlaybackController not available during playback')
          if (this.audioElement) {
            console.debug('[FloatingAudioPlayer] Attempting to reinitialize PlaybackController')
            this.playbackController = new PlaybackController(this.audioElement)
          }
          if (!this.playbackController) {
            throw new Error('PlaybackController not available after reinitialization')
          }
        }

        // Validate URL
        if (!trackData.url) {
          throw new Error(`No audio URL provided in track data: ${JSON.stringify(trackData)}`)
        }

        // Check if aborted
        if (signal.aborted) {
          throw new DOMException('Playback aborted', 'AbortError')
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

        // Update global state (for backward compatibility)
        if (window.floatingPlayerStore) {
          window.floatingPlayerStore.currentTrack = trackData
        }

        // Check if aborted before playing
        if (signal.aborted) {
          throw new DOMException('Playback aborted', 'AbortError')
        }

        // Play the new track using PlaybackController for safe playback
        console.debug('[FloatingAudioPlayer] Attempting to play audio using PlaybackController...')
        await this.playbackController.safePlay(true)

        console.debug('[FloatingAudioPlayer] Audio playback started successfully')
      }
    }

    // Enqueue the playback item
    this.playbackQueue.enqueue(playbackItem)

    try {
      await this.playbackQueue.process()
    } catch (error) {
      // Enhanced error handling with specific AbortError treatment
      if (error.name === 'AbortError') {
        console.debug('[FloatingAudioPlayer] Playback was safely aborted:', error.message)
        this.stateManager.setState(AudioStateManager.STATES.IDLE)
      } else {
        // Log all other errors with details
        console.error('[FloatingAudioPlayer] Failed to play audio:', {
          error: error,
          errorName: error.name,
          errorMessage: error.message,
          audioSrc: this.audioElement?.src,
          trackData: trackData
        })

        // Update state to stopped on error
        this.stateManager.setState(AudioStateManager.STATES.STOPPED)

        // Handle specific error types
        if (error.name === 'NotAllowedError') {
          console.error('[FloatingAudioPlayer] Playback not allowed. User interaction may be required.')
        } else if (error.name === 'NotSupportedError') {
          console.error('[FloatingAudioPlayer] Media format not supported.')
        }
      }
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
      const currentState = this.stateManager.getState()

      // Check current state and transition accordingly
      if (currentState === AudioStateManager.STATES.PLAYING) {
        // Currently playing - pause it
        console.debug('[FloatingAudioPlayer] Toggling to pause')
        this.audioElement.pause()
        // State will be updated by handleMediaPause event
      } else if (currentState === AudioStateManager.STATES.PAUSED) {
        // Currently paused - play it using PlaybackController for safe playback
        console.debug('[FloatingAudioPlayer] Toggling to play')
        await this.playbackController.safePlay(false) // Don't pause before playing since we're already paused
        // State will be updated by handleMediaPlay event
      } else {
        console.warn('[FloatingAudioPlayer] Cannot toggle play from state:', currentState)
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

    // Update state manager
    this.stateManager.setState(AudioStateManager.STATES.STOPPED)
    this.stateManager.clearCurrentTrack()

    this.hide()

    // Clear global state (for backward compatibility)
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
      const isCurrentTrack = this.stateManager.isCurrentTrack(trackId)
      const isPlaying = isCurrentTrack && this.stateManager.getState() === AudioStateManager.STATES.PLAYING

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