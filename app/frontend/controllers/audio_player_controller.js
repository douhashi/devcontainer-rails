import { Controller } from '@hotwired/stimulus'
import Plyr from 'plyr'

export default class extends Controller {
  static targets = ['player']
  static values = { autoplay: Boolean }
  static currentPlayer = null

  connect() {
    this.initializePlayer()
  }

  disconnect() {
    if (this.player) {
      this.player.destroy()
    }
    
    if (this.constructor.currentPlayer === this.player) {
      this.constructor.currentPlayer = null
    }
  }

  initializePlayer() {
    if (!this.playerTarget) return

    const audioUrl = this.playerTarget.dataset.audioUrl
    
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
        controls: false,
        seek: true
      },
      debug: false
    })

    this.player.on('play', () => {
      this.loadAudioSource()
      this.stopOtherPlayers()
      this.constructor.currentPlayer = this.player
    })

    this.player.on('error', (event) => {
      console.error('Audio player error:', event)
      this.showError('音声ファイルを読み込めませんでした')
    })


    if (this.autoplayValue) {
      this.player.autoplay = true
    }
  }

  loadAudioSource() {
    if (this.playerTarget.src) {
      return
    }

    const audioUrl = this.playerTarget.dataset.audioUrl
    if (audioUrl) {
      this.playerTarget.src = audioUrl
      this.playerTarget.load()
    }
  }

  stopOtherPlayers() {
    if (this.constructor.currentPlayer && 
        this.constructor.currentPlayer !== this.player) {
      this.constructor.currentPlayer.pause()
    }
  }

  showError(message) {
    const errorElement = document.createElement('div')
    errorElement.className = 'text-red-400 text-sm'
    errorElement.textContent = message
    
    if (this.playerTarget.parentNode) {
      this.playerTarget.parentNode.replaceChild(errorElement, this.playerTarget)
    }
  }

  // Static method accessor for currentPlayer
  static get currentPlayer() {
    return this._currentPlayer
  }

  static set currentPlayer(player) {
    this._currentPlayer = player
  }
}