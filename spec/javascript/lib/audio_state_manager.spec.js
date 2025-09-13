import { AudioStateManager } from '../../../app/frontend/lib/audio_state_manager'

describe('AudioStateManager', () => {
  let manager

  beforeEach(() => {
    // Clear any existing singleton instance
    AudioStateManager._instance = null
    manager = AudioStateManager.getInstance()
  })

  afterEach(() => {
    manager.cleanup()
    AudioStateManager._instance = null
  })

  describe('Singleton pattern', () => {
    it('should return the same instance when called multiple times', () => {
      const instance1 = AudioStateManager.getInstance()
      const instance2 = AudioStateManager.getInstance()
      expect(instance1).toBe(instance2)
    })
  })

  describe('State management', () => {
    it('should initialize with IDLE state', () => {
      expect(manager.getState()).toBe(AudioStateManager.STATES.IDLE)
    })

    it('should allow valid state transitions', () => {
      // IDLE -> LOADING
      expect(manager.setState(AudioStateManager.STATES.LOADING)).toBe(true)
      expect(manager.getState()).toBe(AudioStateManager.STATES.LOADING)

      // LOADING -> PLAYING
      expect(manager.setState(AudioStateManager.STATES.PLAYING)).toBe(true)
      expect(manager.getState()).toBe(AudioStateManager.STATES.PLAYING)

      // PLAYING -> PAUSED
      expect(manager.setState(AudioStateManager.STATES.PAUSED)).toBe(true)
      expect(manager.getState()).toBe(AudioStateManager.STATES.PAUSED)

      // PAUSED -> PLAYING
      expect(manager.setState(AudioStateManager.STATES.PLAYING)).toBe(true)
      expect(manager.getState()).toBe(AudioStateManager.STATES.PLAYING)

      // PLAYING -> STOPPED
      expect(manager.setState(AudioStateManager.STATES.STOPPED)).toBe(true)
      expect(manager.getState()).toBe(AudioStateManager.STATES.STOPPED)
    })

    it('should prevent invalid state transitions', () => {
      // IDLE -> PLAYING (must go through LOADING first)
      expect(manager.setState(AudioStateManager.STATES.PLAYING)).toBe(false)
      expect(manager.getState()).toBe(AudioStateManager.STATES.IDLE)

      // Set to LOADING then PLAYING for valid state
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setState(AudioStateManager.STATES.PLAYING)

      // PLAYING -> IDLE (should go to STOPPED first)
      expect(manager.setState(AudioStateManager.STATES.IDLE)).toBe(false)
      expect(manager.getState()).toBe(AudioStateManager.STATES.PLAYING)
    })

    it('should validate state transitions with canTransitionTo', () => {
      // From IDLE
      expect(manager.canTransitionTo(AudioStateManager.STATES.LOADING)).toBe(true)
      expect(manager.canTransitionTo(AudioStateManager.STATES.PLAYING)).toBe(false)
      expect(manager.canTransitionTo(AudioStateManager.STATES.PAUSED)).toBe(false)

      // Move to PLAYING
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setState(AudioStateManager.STATES.PLAYING)

      // From PLAYING
      expect(manager.canTransitionTo(AudioStateManager.STATES.PAUSED)).toBe(true)
      expect(manager.canTransitionTo(AudioStateManager.STATES.STOPPED)).toBe(true)
      expect(manager.canTransitionTo(AudioStateManager.STATES.IDLE)).toBe(false)
    })
  })

  describe('Track management', () => {
    const track1 = { id: 1, title: 'Track 1', url: 'http://example.com/track1.mp3' }
    const track2 = { id: 2, title: 'Track 2', url: 'http://example.com/track2.mp3' }

    it('should set and get current track', () => {
      expect(manager.getCurrentTrack()).toBeNull()

      manager.setCurrentTrack(track1)
      expect(manager.getCurrentTrack()).toEqual(track1)

      manager.setCurrentTrack(track2)
      expect(manager.getCurrentTrack()).toEqual(track2)
    })

    it('should clear current track', () => {
      manager.setCurrentTrack(track1)
      expect(manager.getCurrentTrack()).toEqual(track1)

      manager.clearCurrentTrack()
      expect(manager.getCurrentTrack()).toBeNull()
    })

    it('should check if a track is current', () => {
      manager.setCurrentTrack(track1)
      expect(manager.isCurrentTrack(track1.id)).toBe(true)
      expect(manager.isCurrentTrack(track2.id)).toBe(false)

      manager.clearCurrentTrack()
      expect(manager.isCurrentTrack(track1.id)).toBe(false)
    })
  })

  describe('Event handling', () => {
    it('should emit statechange event when state changes', (done) => {
      const listener = jest.fn((event) => {
        expect(event.detail.oldState).toBe(AudioStateManager.STATES.IDLE)
        expect(event.detail.newState).toBe(AudioStateManager.STATES.LOADING)
        expect(event.detail.timestamp).toBeDefined()
        done()
      })

      manager.addEventListener('statechange', listener)
      manager.setState(AudioStateManager.STATES.LOADING)
    })

    it('should emit trackchange event when track changes', (done) => {
      const track = { id: 1, title: 'Track 1', url: 'http://example.com/track1.mp3' }
      const listener = jest.fn((event) => {
        expect(event.detail.oldTrack).toBeNull()
        expect(event.detail.newTrack).toEqual(track)
        expect(event.detail.timestamp).toBeDefined()
        done()
      })

      manager.addEventListener('trackchange', listener)
      manager.setCurrentTrack(track)
    })

    it('should not emit events when state does not change', () => {
      const listener = jest.fn()
      manager.addEventListener('statechange', listener)

      // Try to set same state
      manager.setState(AudioStateManager.STATES.IDLE)
      expect(listener).not.toHaveBeenCalled()
    })

    it('should remove event listeners', () => {
      const listener = jest.fn()
      manager.addEventListener('statechange', listener)
      manager.removeEventListener('statechange', listener)

      manager.setState(AudioStateManager.STATES.LOADING)
      expect(listener).not.toHaveBeenCalled()
    })

    it('should handle multiple listeners for the same event', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()

      manager.addEventListener('statechange', listener1)
      manager.addEventListener('statechange', listener2)

      manager.setState(AudioStateManager.STATES.LOADING)

      expect(listener1).toHaveBeenCalled()
      expect(listener2).toHaveBeenCalled()
    })
  })

  describe('Error handling', () => {
    it('should validate track data structure', () => {
      const invalidTrack = { title: 'No ID' }
      expect(() => manager.setCurrentTrack(invalidTrack)).toThrow('Invalid track: missing id')

      const trackWithoutUrl = { id: 1, title: 'No URL' }
      expect(() => manager.setCurrentTrack(trackWithoutUrl)).toThrow('Invalid track: missing url')
    })

    it('should handle invalid state values', () => {
      expect(() => manager.setState('INVALID_STATE')).toThrow('Invalid state: INVALID_STATE')
    })

    it('should handle errors in event listeners gracefully', () => {
      const errorListener = jest.fn(() => {
        throw new Error('Listener error')
      })
      const normalListener = jest.fn()

      manager.addEventListener('statechange', errorListener)
      manager.addEventListener('statechange', normalListener)

      // Should not throw, and other listeners should still be called
      expect(() => manager.setState(AudioStateManager.STATES.LOADING)).not.toThrow()
      expect(normalListener).toHaveBeenCalled()
    })
  })

  describe('Cleanup', () => {
    it('should remove all event listeners on cleanup', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()

      manager.addEventListener('statechange', listener1)
      manager.addEventListener('trackchange', listener2)

      manager.cleanup()

      // Try to trigger events after cleanup
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setCurrentTrack({ id: 1, title: 'Test', url: 'test.mp3' })

      expect(listener1).not.toHaveBeenCalled()
      expect(listener2).not.toHaveBeenCalled()
    })

    it('should reset state on cleanup', () => {
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setState(AudioStateManager.STATES.PLAYING)
      manager.setCurrentTrack({ id: 1, title: 'Test', url: 'test.mp3' })

      manager.cleanup()

      expect(manager.getState()).toBe(AudioStateManager.STATES.IDLE)
      expect(manager.getCurrentTrack()).toBeNull()
    })
  })

  describe('State machine integrity', () => {
    it('should define all valid transitions', () => {
      const transitions = AudioStateManager.STATE_TRANSITIONS

      // Check that all states have transition rules defined
      Object.values(AudioStateManager.STATES).forEach(state => {
        expect(transitions).toHaveProperty(state)
        expect(Array.isArray(transitions[state])).toBe(true)
      })
    })

    it('should handle rapid state changes correctly', () => {
      // Simulate rapid state changes
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setState(AudioStateManager.STATES.PLAYING)
      manager.setState(AudioStateManager.STATES.PAUSED)
      manager.setState(AudioStateManager.STATES.PLAYING)
      manager.setState(AudioStateManager.STATES.STOPPED)

      expect(manager.getState()).toBe(AudioStateManager.STATES.STOPPED)
    })
  })

  describe('History tracking', () => {
    it('should track state history', () => {
      manager.setState(AudioStateManager.STATES.LOADING)
      manager.setState(AudioStateManager.STATES.PLAYING)
      manager.setState(AudioStateManager.STATES.PAUSED)

      const history = manager.getStateHistory()
      expect(history).toHaveLength(4) // Including initial IDLE
      expect(history[0].state).toBe(AudioStateManager.STATES.IDLE)
      expect(history[1].state).toBe(AudioStateManager.STATES.LOADING)
      expect(history[2].state).toBe(AudioStateManager.STATES.PLAYING)
      expect(history[3].state).toBe(AudioStateManager.STATES.PAUSED)

      // Check timestamps are in order
      for (let i = 1; i < history.length; i++) {
        expect(history[i].timestamp).toBeGreaterThanOrEqual(history[i - 1].timestamp)
      }
    })

    it('should limit history size', () => {
      // Create many state changes
      for (let i = 0; i < 30; i++) {
        manager.setState(AudioStateManager.STATES.LOADING)
        manager.setState(AudioStateManager.STATES.PLAYING)
        manager.setState(AudioStateManager.STATES.PAUSED)
        manager.setState(AudioStateManager.STATES.STOPPED)
        manager.setState(AudioStateManager.STATES.IDLE)
      }

      const history = manager.getStateHistory()
      expect(history.length).toBeLessThanOrEqual(20) // Max history size
    })
  })
})