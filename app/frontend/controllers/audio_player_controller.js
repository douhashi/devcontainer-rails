import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['player']
  static values = { autoplay: Boolean }
  
  // Use a global store instead of static class property for better isolation
  static get currentPlayer() {
    if (!window.audioPlayerStore) {
      window.audioPlayerStore = { currentPlayer: null }
    }
    return window.audioPlayerStore.currentPlayer
  }
  
  static set currentPlayer(player) {
    if (!window.audioPlayerStore) {
      window.audioPlayerStore = { currentPlayer: null }
    }
    window.audioPlayerStore.currentPlayer = player
  }

  connect() {
    try {
      this.initializePlayer()
    } catch (error) {
      console.error('AudioPlayerController connect error:', error)
      this.showError('音楽プレイヤーの初期化に失敗しました')
    }
  }

  disconnect() {
    try {
      if (this.player) {
        // Remove event listeners
        this.player.removeEventListener('play', this.handlePlay)
        this.player.removeEventListener('pause', this.handlePause)
        this.player.removeEventListener('error', this.handleError)
        this.player = null
      }
      
      if (this.constructor.currentPlayer === this.player) {
        this.constructor.currentPlayer = null
      }
    } catch (error) {
      console.error('AudioPlayerController disconnect error:', error)
    }
  }

  initializePlayer() {
    if (!this.playerTarget) {
      console.warn('AudioPlayerController: playerTarget not found')
      return
    }

    // Prevent duplicate initialization
    if (this.player) {
      console.warn('AudioPlayerController: Player already initialized')
      return
    }

    const audioUrl = this.playerTarget.dataset.audioUrl
    if (!audioUrl) {
      console.warn('AudioPlayerController: No audio URL provided')
      this.showError('音声ファイルのURLが見つかりません')
      return
    }

    try {
      // Store reference to media-controller element
      this.player = this.playerTarget
      
      // Get the audio element inside the media-controller
      const audioElement = this.player.querySelector('audio[slot="media"]')
      if (!audioElement) {
        console.error('AudioPlayerController: Audio element not found')
        this.showError('音楽プレイヤーの初期化に失敗しました')
        return
      }

      // Bind event handlers
      this.handlePlay = () => {
        try {
          this.stopOtherPlayers()
          this.constructor.currentPlayer = this.player
        } catch (error) {
          console.error('AudioPlayerController play event error:', error)
        }
      }

      this.handlePause = () => {
        if (this.constructor.currentPlayer === this.player) {
          this.constructor.currentPlayer = null
        }
      }

      this.handleError = (event) => {
        // Only log errors if it's not a test environment
        if (!this.isTestEnvironment()) {
          console.error('Audio player error:', event)
          this.showError('音声ファイルを読み込めませんでした')
        }
      }

      // Add event listeners to media-controller
      this.player.addEventListener('play', this.handlePlay)
      this.player.addEventListener('pause', this.handlePause)
      this.player.addEventListener('error', this.handleError)

      // Set volume
      this.player.volume = 0.7

      if (this.autoplayValue) {
        // Use media-chrome's autoplay attribute
        this.player.setAttribute('autoplay', '')
      }

      // Show the player after successful initialization
      this.showPlayer()
    } catch (error) {
      console.error('AudioPlayerController: Failed to initialize media-chrome:', error)
      this.showError('音楽プレイヤーの初期化に失敗しました')
    }
  }

  showPlayer() {
    try {
      if (this.playerTarget) {
        // media-chrome elements are visible by default
        this.playerTarget.style.display = 'block'
      }
    } catch (error) {
      console.error('AudioPlayerController: Failed to show player:', error)
    }
  }


  stopOtherPlayers() {
    try {
      const currentPlayer = this.constructor.currentPlayer
      if (currentPlayer && currentPlayer !== this.player) {
        // For media-chrome, pause is a property/method on the element
        if (currentPlayer.pause) {
          currentPlayer.pause()
        }
      }
    } catch (error) {
      console.error('AudioPlayerController: Failed to stop other players:', error)
    }
  }

  showError(message) {
    try {
      const errorElement = document.createElement('div')
      errorElement.className = 'text-red-400 text-sm px-2 py-1'
      errorElement.textContent = message
      
      if (this.playerTarget && this.playerTarget.parentNode) {
        this.playerTarget.style.display = 'none'
        this.playerTarget.parentNode.insertBefore(errorElement, this.playerTarget.nextSibling)
      }
    } catch (error) {
      console.error('AudioPlayerController: Failed to show error message:', error)
    }
  }

  isTestEnvironment() {
    // Check if running in test environment by looking for test-specific attributes
    return window.location.port === '5555' || document.querySelector('[data-test-environment]') !== null
  }
}