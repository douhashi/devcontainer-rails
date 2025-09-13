import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "trackTitle", "playButton", "playIcon", "pauseIcon"]

  connect() {
    console.log('FloatingAudioPlayerController connected')
    this.initializePlayer()
    this.setupEventListeners()
    this.trackList = []
    this.currentTrackIndex = 0
  }

  disconnect() {
    if (this.player) {
      // Remove event listeners from media-controller
      this.player.removeEventListener('play', this.handleMediaPlay)
      this.player.removeEventListener('pause', this.handleMediaPause)
      this.player.removeEventListener('ended', this.handleMediaEnded)
      this.player = null
    }
    this.removeEventListeners()
  }

  initializePlayer() {
    console.log('FloatingAudioPlayerController: Initializing media-chrome player')
    
    if (!this.audioTarget) {
      console.error('FloatingAudioPlayerController: Audio target not found')
      return
    }
    
    // Store reference to media-controller element
    this.player = this.audioTarget
    
    // Get the audio element inside the media-controller
    this.audioElement = this.player.querySelector('audio[slot="media"]')
    if (!this.audioElement) {
      console.error('FloatingAudioPlayerController: Audio element not found')
      return
    }
    
    // Bind event handlers
    this.handleMediaPlay = () => {
      console.log('FloatingAudioPlayerController: Player started playing')
      this.updatePlayButton(true)
      this.stopOtherPlayers()
    }
    
    this.handleMediaPause = () => {
      console.log('FloatingAudioPlayerController: Player paused')
      this.updatePlayButton(false)
    }
    
    this.handleMediaEnded = () => {
      console.log('FloatingAudioPlayerController: Player ended')
      this.next()
    }
    
    // Add event listeners to media-controller
    this.player.addEventListener('play', this.handleMediaPlay)
    this.player.addEventListener('pause', this.handleMediaPause)
    this.player.addEventListener('ended', this.handleMediaEnded)
    
    // Set default volume on audio element
    if (this.audioElement) {
      this.audioElement.volume = 0.8
    }
    
    console.log('FloatingAudioPlayerController: media-controller player initialized successfully')
  }

  setupEventListeners() {
    console.log('FloatingAudioPlayerController: Setting up event listeners')
    this.audioPlayHandler = this.handleAudioPlayEvent.bind(this)
    this.playHandler = this.handlePlayEvent.bind(this)
    this.contentPlayHandler = this.handleContentPlayEvent.bind(this)
    
    // New unified event listener
    document.addEventListener("audio:play", this.audioPlayHandler)
    
    // Legacy event listeners (for backward compatibility during transition)
    document.addEventListener("track:play", this.playHandler)
    document.addEventListener("content:play", this.contentPlayHandler)
    console.log('FloatingAudioPlayerController: Event listeners setup complete')
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
    console.log('FloatingAudioPlayerController: content:play event received', event.detail)
    const eventDetail = event.detail
    
    const trackData = {
      id: `content-${eventDetail.contentId}`,
      title: eventDetail.theme || "Untitled",
      url: eventDetail.audioUrl,
      contentId: eventDetail.contentId,
      contentTitle: eventDetail.theme || "Untitled"
    }
    
    console.log('FloatingAudioPlayerController: Track data prepared', trackData)
    
    // Create single track for content audio
    this.trackList = [trackData]
    this.currentTrackIndex = 0
    
    this.playTrack(trackData)
    this.show()
    
    console.log('FloatingAudioPlayerController: content:play event handled successfully')
  }

  handleAudioPlayEvent(event) {
    console.log('FloatingAudioPlayerController: audio:play event received (unified)', event.detail)
    const eventDetail = event.detail

    // Convert unified data format to internal track format
    const trackData = {
      id: eventDetail.type === "track" ? eventDetail.id : `content-${eventDetail.id}`,
      title: eventDetail.title,
      url: eventDetail.audioUrl,
      contentId: eventDetail.contentId || eventDetail.id,
      contentTitle: eventDetail.contentTitle || eventDetail.title
    }

    console.log('FloatingAudioPlayerController: Unified track data prepared', trackData)

    // Use track list if available (for tracks), otherwise create single item list
    if (eventDetail.trackList && eventDetail.trackList.length > 0) {
      this.trackList = eventDetail.trackList.map(track => ({
        id: track.id,
        title: track.title,
        url: track.url || track.audioUrl
      }))
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

    console.log('FloatingAudioPlayerController: audio:play event handled successfully')
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

  playTrack(trackData) {
    if (!trackData) return
    
    this.trackTitleTarget.textContent = trackData.title || "Untitled"
    
    // Set audio source for media-chrome
    if (this.audioElement) {
      this.audioElement.src = trackData.url
    }
    
    // Update global state
    if (window.floatingPlayerStore) {
      window.floatingPlayerStore.currentTrack = trackData
    }
    
    // Play using audio element's play method
    if (this.audioElement) {
      this.audioElement.play().catch(error => {
        console.error('Failed to play audio:', error)
      })
    }
    this.updateAllPlayButtons(trackData.id)
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

  togglePlay() {
    // Check if media is playing using audio element's paused property
    if (this.audioElement && !this.audioElement.paused) {
      this.audioElement.pause()
    } else if (this.audioElement) {
      this.audioElement.play().catch(error => {
        console.error('Failed to play audio:', error)
      })
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