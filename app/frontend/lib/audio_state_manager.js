/**
 * AudioStateManager - グローバルなオーディオ状態管理クラス
 * Singleton パターンで実装され、アプリケーション全体で一つのインスタンスを共有
 */
export class AudioStateManager {
  // Static state definitions
  static STATES = Object.freeze({
    IDLE: 'idle',
    LOADING: 'loading',
    PLAYING: 'playing',
    PAUSED: 'paused',
    STOPPED: 'stopped'
  })

  // Valid state transitions
  static STATE_TRANSITIONS = Object.freeze({
    [AudioStateManager.STATES.IDLE]: [
      AudioStateManager.STATES.LOADING
    ],
    [AudioStateManager.STATES.LOADING]: [
      AudioStateManager.STATES.PLAYING,
      AudioStateManager.STATES.STOPPED,
      AudioStateManager.STATES.IDLE
    ],
    [AudioStateManager.STATES.PLAYING]: [
      AudioStateManager.STATES.PAUSED,
      AudioStateManager.STATES.STOPPED,
      AudioStateManager.STATES.LOADING
    ],
    [AudioStateManager.STATES.PAUSED]: [
      AudioStateManager.STATES.PLAYING,
      AudioStateManager.STATES.STOPPED,
      AudioStateManager.STATES.LOADING
    ],
    [AudioStateManager.STATES.STOPPED]: [
      AudioStateManager.STATES.IDLE,
      AudioStateManager.STATES.LOADING
    ]
  })

  // Singleton instance
  static _instance = null

  /**
   * Get singleton instance of AudioStateManager
   * @returns {AudioStateManager}
   */
  static getInstance() {
    if (!AudioStateManager._instance) {
      AudioStateManager._instance = new AudioStateManager()
    }
    return AudioStateManager._instance
  }

  constructor() {
    // Prevent direct instantiation
    if (AudioStateManager._instance) {
      throw new Error('Use AudioStateManager.getInstance() instead of new AudioStateManager()')
    }

    this._state = AudioStateManager.STATES.IDLE
    this._currentTrack = null
    this._stateHistory = [{ state: AudioStateManager.STATES.IDLE, timestamp: Date.now() }]
    this._maxHistorySize = 20
    this._listeners = new Map()
    this._isTransitioning = false
  }

  /**
   * Get current state
   * @returns {string}
   */
  getState() {
    return this._state
  }

  /**
   * Set state with validation
   * @param {string} newState
   * @returns {boolean} Success status
   */
  setState(newState) {
    // Validate state value
    if (!Object.values(AudioStateManager.STATES).includes(newState)) {
      throw new Error(`Invalid state: ${newState}`)
    }

    // Check if already in the same state
    if (this._state === newState) {
      return false
    }

    // Check if transition is valid
    if (!this.canTransitionTo(newState)) {
      console.warn(`Invalid state transition: ${this._state} -> ${newState}`)
      return false
    }

    // Prevent concurrent state transitions
    if (this._isTransitioning) {
      console.warn('State transition already in progress')
      return false
    }

    this._isTransitioning = true
    const oldState = this._state

    try {
      // Update state
      this._state = newState

      // Record in history
      this._addToHistory(newState)

      // Emit state change event
      this._emitEvent('statechange', {
        oldState,
        newState,
        timestamp: Date.now()
      })

      return true
    } finally {
      this._isTransitioning = false
    }
  }

  /**
   * Check if can transition to a given state
   * @param {string} targetState
   * @returns {boolean}
   */
  canTransitionTo(targetState) {
    const validTransitions = AudioStateManager.STATE_TRANSITIONS[this._state] || []
    return validTransitions.includes(targetState)
  }

  /**
   * Get current track
   * @returns {Object|null}
   */
  getCurrentTrack() {
    return this._currentTrack
  }

  /**
   * Set current track
   * @param {Object} track
   */
  setCurrentTrack(track) {
    // Validate track structure
    if (!track.id) {
      throw new Error('Invalid track: missing id')
    }
    if (!track.url) {
      throw new Error('Invalid track: missing url')
    }

    const oldTrack = this._currentTrack
    this._currentTrack = track

    // Emit track change event
    this._emitEvent('trackchange', {
      oldTrack,
      newTrack: track,
      timestamp: Date.now()
    })
  }

  /**
   * Clear current track
   */
  clearCurrentTrack() {
    const oldTrack = this._currentTrack
    this._currentTrack = null

    if (oldTrack) {
      this._emitEvent('trackchange', {
        oldTrack,
        newTrack: null,
        timestamp: Date.now()
      })
    }
  }

  /**
   * Check if given track ID is current
   * @param {string|number} trackId
   * @returns {boolean}
   */
  isCurrentTrack(trackId) {
    return this._currentTrack && this._currentTrack.id === trackId
  }

  /**
   * Add event listener
   * @param {string} eventType
   * @param {Function} listener
   */
  addEventListener(eventType, listener) {
    if (!this._listeners.has(eventType)) {
      this._listeners.set(eventType, new Set())
    }
    this._listeners.get(eventType).add(listener)
  }

  /**
   * Remove event listener
   * @param {string} eventType
   * @param {Function} listener
   */
  removeEventListener(eventType, listener) {
    if (this._listeners.has(eventType)) {
      this._listeners.get(eventType).delete(listener)
    }
  }

  /**
   * Get state history
   * @returns {Array}
   */
  getStateHistory() {
    return [...this._stateHistory]
  }

  /**
   * Cleanup and reset
   */
  cleanup() {
    this._state = AudioStateManager.STATES.IDLE
    this._currentTrack = null
    this._stateHistory = [{ state: AudioStateManager.STATES.IDLE, timestamp: Date.now() }]
    this._listeners.clear()
    this._isTransitioning = false
  }

  /**
   * Add state to history
   * @private
   * @param {string} state
   */
  _addToHistory(state) {
    this._stateHistory.push({
      state,
      timestamp: Date.now()
    })

    // Limit history size
    if (this._stateHistory.length > this._maxHistorySize) {
      this._stateHistory = this._stateHistory.slice(-this._maxHistorySize)
    }
  }

  /**
   * Emit custom event
   * @private
   * @param {string} eventType
   * @param {Object} detail
   */
  _emitEvent(eventType, detail) {
    if (!this._listeners.has(eventType)) {
      return
    }

    const listeners = this._listeners.get(eventType)
    const event = new CustomEvent(eventType, { detail })

    listeners.forEach(listener => {
      try {
        listener(event)
      } catch (error) {
        console.error(`Error in ${eventType} listener:`, error)
      }
    })
  }
}