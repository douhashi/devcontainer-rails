import { Controller } from '@hotwired/stimulus'
import Plyr from 'plyr'

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
        // Remove event listeners before destroying
        this.player.off('play')
        this.player.off('error')
        this.player.destroy()
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
      this.player = new Plyr(this.playerTarget, {
        controls: ['play-large', 'play', 'progress', 'current-time', 'mute', 'volume'],
        volume: 0.7,
        seekTime: 5,
        displayDuration: true,
        invertTime: false,
        captions: {
          active: false,
          language: 'auto',
          update: false
        },
        keyboard: {
          focused: true,
          global: false
        },
        tooltips: {
          controls: true,
          seek: true
        },
        debug: false,
        // Dark theme specific settings
        loadSprite: false,
        iconPrefix: 'plyr',
        iconUrl: null
      })

      // Bind event handlers with error handling
      this.player.on('play', () => {
        try {
          this.loadAudioSource()
          this.stopOtherPlayers()
          this.constructor.currentPlayer = this.player
        } catch (error) {
          console.error('AudioPlayerController play event error:', error)
        }
      })

      this.player.on('error', (event) => {
        console.error('Audio player error:', event)
        this.showError('音声ファイルを読み込めませんでした')
      })

      // Add pause event to clear current player
      this.player.on('pause', () => {
        if (this.constructor.currentPlayer === this.player) {
          this.constructor.currentPlayer = null
        }
      })

      if (this.autoplayValue) {
        this.player.autoplay = true
      }

      // Show the player after successful initialization
      this.showPlayer()
    } catch (error) {
      console.error('AudioPlayerController: Failed to initialize Plyr:', error)
      this.showError('音楽プレイヤーの初期化に失敗しました')
    }
  }

  showPlayer() {
    try {
      if (this.playerTarget) {
        this.playerTarget.style.visibility = 'visible'
      }
    } catch (error) {
      console.error('AudioPlayerController: Failed to show player:', error)
    }
  }

  loadAudioSource() {
    try {
      if (this.playerTarget.src) {
        return
      }

      const audioUrl = this.playerTarget.dataset.audioUrl
      if (audioUrl) {
        this.playerTarget.src = audioUrl
        this.playerTarget.load()
      }
    } catch (error) {
      console.error('AudioPlayerController: Failed to load audio source:', error)
      this.showError('音声ファイルの読み込みに失敗しました')
    }
  }

  stopOtherPlayers() {
    try {
      const currentPlayer = this.constructor.currentPlayer
      if (currentPlayer && currentPlayer !== this.player) {
        if (typeof currentPlayer.pause === 'function') {
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
}