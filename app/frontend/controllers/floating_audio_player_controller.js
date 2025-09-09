import { Controller } from "@hotwired/stimulus"
import Plyr from "plyr"

export default class extends Controller {
  static targets = ["audio", "trackTitle", "playButton", "playIcon", "pauseIcon"]

  connect() {
    this.initializePlayer()
    this.setupEventListeners()
    this.trackList = []
    this.currentTrackIndex = 0
  }

  disconnect() {
    if (this.player) {
      this.player.destroy()
    }
    this.removeEventListeners()
  }

  initializePlayer() {
    const config = this.audioTarget.dataset.plyrConfig
    this.player = new Plyr(this.audioTarget, config ? JSON.parse(config) : {})
    
    this.player.on("play", () => {
      this.updatePlayButton(true)
      this.stopOtherPlayers()
    })
    
    this.player.on("pause", () => {
      this.updatePlayButton(false)
    })
    
    this.player.on("ended", () => {
      this.next()
    })
  }

  setupEventListeners() {
    this.playHandler = this.handlePlayEvent.bind(this)
    this.contentPlayHandler = this.handleContentPlayEvent.bind(this)
    document.addEventListener("track:play", this.playHandler)
    document.addEventListener("content:play", this.contentPlayHandler)
  }

  removeEventListeners() {
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
    this.player.source = {
      type: "audio",
      sources: [
        {
          src: trackData.url,
          type: "audio/mpeg"
        }
      ]
    }
    
    // Update global state
    if (window.floatingPlayerStore) {
      window.floatingPlayerStore.currentTrack = trackData
    }
    
    this.player.play()
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
    if (this.player.playing) {
      this.player.pause()
    } else {
      this.player.play()
    }
  }

  close() {
    this.player.stop()
    this.hide()
    this.updateAllPlayButtons(null)
    
    // Clear global state
    if (window.floatingPlayerStore) {
      window.floatingPlayerStore.currentTrack = null
    }
  }

  show() {
    this.element.classList.remove("hidden")
    this.element.classList.add("translate-y-0")
    this.element.classList.remove("translate-y-full")
  }

  hide() {
    this.element.classList.add("hidden")
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
    document.querySelectorAll("[id^='play-button-']").forEach(button => {
      const trackId = parseInt(button.dataset.trackId)
      const isPlaying = trackId === currentTrackId
      button.dataset.playing = isPlaying
      
      // Update button visual state
      if (isPlaying) {
        button.classList.remove("bg-blue-600")
        button.classList.add("bg-blue-700")
      } else {
        button.classList.remove("bg-blue-700")
        button.classList.add("bg-blue-600")
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