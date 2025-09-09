// Global store for floating player state
class FloatingPlayerStore {
  constructor() {
    this.currentTrack = null
    this.isPlaying = false
  }

  setCurrentTrack(track) {
    this.currentTrack = track
  }

  clearCurrentTrack() {
    this.currentTrack = null
    this.isPlaying = false
  }

  setPlaying(playing) {
    this.isPlaying = playing
  }
}

// Create singleton instance
if (!window.floatingPlayerStore) {
  window.floatingPlayerStore = new FloatingPlayerStore()
}

export default window.floatingPlayerStore