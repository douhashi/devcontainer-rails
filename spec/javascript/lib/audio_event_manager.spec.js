import { AudioEventManager } from '../../../app/frontend/lib/audio_event_manager'

describe('AudioEventManager', () => {
  let manager
  let element1
  let element2

  beforeEach(() => {
    manager = new AudioEventManager()
    element1 = document.createElement('div')
    element2 = document.createElement('audio')
  })

  afterEach(() => {
    manager.cleanup()
  })

  describe('Event listener management', () => {
    it('should add event listeners to elements', () => {
      const listener = jest.fn()

      manager.addListener(element1, 'click', listener)

      // Trigger event
      element1.dispatchEvent(new Event('click'))

      expect(listener).toHaveBeenCalledTimes(1)
    })

    it('should remove event listeners from elements', () => {
      const listener = jest.fn()

      manager.addListener(element1, 'click', listener)
      manager.removeListener(element1, 'click', listener)

      // Trigger event
      element1.dispatchEvent(new Event('click'))

      expect(listener).not.toHaveBeenCalled()
    })

    it('should handle multiple listeners for same event', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()

      manager.addListener(element1, 'click', listener1)
      manager.addListener(element1, 'click', listener2)

      element1.dispatchEvent(new Event('click'))

      expect(listener1).toHaveBeenCalledTimes(1)
      expect(listener2).toHaveBeenCalledTimes(1)
    })

    it('should handle different event types on same element', () => {
      const clickListener = jest.fn()
      const focusListener = jest.fn()

      manager.addListener(element1, 'click', clickListener)
      manager.addListener(element1, 'focus', focusListener)

      element1.dispatchEvent(new Event('click'))
      element1.dispatchEvent(new Event('focus'))

      expect(clickListener).toHaveBeenCalledTimes(1)
      expect(focusListener).toHaveBeenCalledTimes(1)
    })

    it('should track listeners across multiple elements', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()

      manager.addListener(element1, 'click', listener1)
      manager.addListener(element2, 'play', listener2)

      element1.dispatchEvent(new Event('click'))
      element2.dispatchEvent(new Event('play'))

      expect(listener1).toHaveBeenCalledTimes(1)
      expect(listener2).toHaveBeenCalledTimes(1)
    })
  })

  describe('WeakMap-based storage', () => {
    it('should automatically clean up when element is garbage collected', () => {
      const listener = jest.fn()
      let tempElement = document.createElement('div')

      manager.addListener(tempElement, 'click', listener)

      // Get listener count before cleanup
      const hasListenersBefore = manager.hasListeners(tempElement)
      expect(hasListenersBefore).toBe(true)

      // Remove reference to element (simulating garbage collection)
      tempElement = null

      // Force garbage collection (if available in test environment)
      if (global.gc) {
        global.gc()
      }

      // WeakMap should handle cleanup automatically
      // (In real scenarios, the element would be garbage collected)
    })

    it('should track if element has listeners', () => {
      expect(manager.hasListeners(element1)).toBe(false)

      const listener = jest.fn()
      manager.addListener(element1, 'click', listener)

      expect(manager.hasListeners(element1)).toBe(true)

      manager.removeListener(element1, 'click', listener)

      // Should still return true if WeakMap entry exists
      // (actual cleanup happens with removeAllListeners or cleanup)
      expect(manager.hasListeners(element1)).toBe(true)
    })
  })

  describe('Bulk operations', () => {
    it('should remove all listeners for a specific element', () => {
      const clickListener = jest.fn()
      const focusListener = jest.fn()
      const blurListener = jest.fn()

      manager.addListener(element1, 'click', clickListener)
      manager.addListener(element1, 'focus', focusListener)
      manager.addListener(element1, 'blur', blurListener)

      manager.removeAllListeners(element1)

      element1.dispatchEvent(new Event('click'))
      element1.dispatchEvent(new Event('focus'))
      element1.dispatchEvent(new Event('blur'))

      expect(clickListener).not.toHaveBeenCalled()
      expect(focusListener).not.toHaveBeenCalled()
      expect(blurListener).not.toHaveBeenCalled()
    })

    it('should remove all listeners for a specific event type on element', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()
      const otherListener = jest.fn()

      manager.addListener(element1, 'click', listener1)
      manager.addListener(element1, 'click', listener2)
      manager.addListener(element1, 'focus', otherListener)

      manager.removeEventListeners(element1, 'click')

      element1.dispatchEvent(new Event('click'))
      element1.dispatchEvent(new Event('focus'))

      expect(listener1).not.toHaveBeenCalled()
      expect(listener2).not.toHaveBeenCalled()
      expect(otherListener).toHaveBeenCalledTimes(1)
    })

    it('should cleanup all listeners on all elements', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()
      const listener3 = jest.fn()

      manager.addListener(element1, 'click', listener1)
      manager.addListener(element2, 'play', listener2)
      manager.addListener(element1, 'focus', listener3)

      manager.cleanup()

      element1.dispatchEvent(new Event('click'))
      element1.dispatchEvent(new Event('focus'))
      element2.dispatchEvent(new Event('play'))

      expect(listener1).not.toHaveBeenCalled()
      expect(listener2).not.toHaveBeenCalled()
      expect(listener3).not.toHaveBeenCalled()
    })
  })

  describe('Event options support', () => {
    it('should support addEventListener options', () => {
      let capturePhaseListener = jest.fn()
      let bubblePhaseListener = jest.fn()

      // Create nested elements for capture/bubble testing
      const parent = document.createElement('div')
      const child = document.createElement('div')
      parent.appendChild(child)

      // Add capture phase listener
      manager.addListener(parent, 'click', capturePhaseListener, { capture: true })
      // Add bubble phase listener
      manager.addListener(parent, 'click', bubblePhaseListener, { capture: false })

      // Dispatch event on child
      child.dispatchEvent(new Event('click', { bubbles: true }))

      expect(capturePhaseListener).toHaveBeenCalled()
      expect(bubblePhaseListener).toHaveBeenCalled()
    })

    it('should support once option', () => {
      const listener = jest.fn()

      manager.addListener(element1, 'click', listener, { once: true })

      element1.dispatchEvent(new Event('click'))
      element1.dispatchEvent(new Event('click'))

      // Should only be called once
      expect(listener).toHaveBeenCalledTimes(1)
    })

    it('should support passive option', () => {
      const listener = jest.fn((e) => {
        // In a passive listener, preventDefault should not work
        e.preventDefault()
      })

      manager.addListener(element1, 'wheel', listener, { passive: true })

      const event = new WheelEvent('wheel', { cancelable: true })
      element1.dispatchEvent(event)

      expect(listener).toHaveBeenCalled()
      // Note: Testing passive behavior is limited in jsdom
    })
  })

  describe('Custom event helpers', () => {
    it('should dispatch custom events', () => {
      const listener = jest.fn()

      element1.addEventListener('custom:event', listener)

      manager.dispatchCustomEvent(element1, 'custom:event', { data: 'test' })

      expect(listener).toHaveBeenCalledTimes(1)
      expect(listener.mock.calls[0][0].detail).toEqual({ data: 'test' })
    })

    it('should create and dispatch audio-specific events', () => {
      const stateChangeListener = jest.fn()
      const trackChangeListener = jest.fn()

      document.addEventListener('audio:statechange', stateChangeListener)
      document.addEventListener('audio:trackchange', trackChangeListener)

      manager.dispatchAudioEvent('statechange', {
        oldState: 'idle',
        newState: 'playing'
      })

      manager.dispatchAudioEvent('trackchange', {
        track: { id: 1, title: 'Test Track' }
      })

      expect(stateChangeListener).toHaveBeenCalledTimes(1)
      expect(trackChangeListener).toHaveBeenCalledTimes(1)

      // Cleanup
      document.removeEventListener('audio:statechange', stateChangeListener)
      document.removeEventListener('audio:trackchange', trackChangeListener)
    })
  })

  describe('Error handling', () => {
    it('should handle errors in listeners gracefully', () => {
      const errorListener = jest.fn(() => {
        throw new Error('Listener error')
      })
      const normalListener = jest.fn()

      manager.addListener(element1, 'click', errorListener)
      manager.addListener(element1, 'click', normalListener)

      // Should not throw
      expect(() => {
        element1.dispatchEvent(new Event('click'))
      }).not.toThrow()

      // Normal listener should still be called
      expect(normalListener).toHaveBeenCalled()
    })

    it('should validate element parameter', () => {
      const listener = jest.fn()

      expect(() => {
        manager.addListener(null, 'click', listener)
      }).toThrow('Element must be a valid DOM element')

      expect(() => {
        manager.addListener('not-an-element', 'click', listener)
      }).toThrow('Element must be a valid DOM element')
    })

    it('should validate listener parameter', () => {
      expect(() => {
        manager.addListener(element1, 'click', null)
      }).toThrow('Listener must be a function')

      expect(() => {
        manager.addListener(element1, 'click', 'not-a-function')
      }).toThrow('Listener must be a function')
    })
  })

  describe('Statistics and debugging', () => {
    it('should track listener statistics', () => {
      const listener1 = jest.fn()
      const listener2 = jest.fn()

      manager.addListener(element1, 'click', listener1)
      manager.addListener(element1, 'focus', listener2)
      manager.addListener(element2, 'play', listener1)

      const stats = manager.getStats()

      expect(stats.totalElements).toBe(2)
      expect(stats.totalListeners).toBe(3)
      expect(stats.byElement).toEqual(expect.objectContaining({
        [element1.tagName]: { events: 2, listeners: 2 },
        [element2.tagName]: { events: 1, listeners: 1 }
      }))
    })

    it('should provide debug information', () => {
      const listener = jest.fn()

      manager.addListener(element1, 'click', listener, { once: true })
      manager.addListener(element2, 'play', listener)

      const debugInfo = manager.getDebugInfo()

      expect(debugInfo).toHaveLength(2)
      expect(debugInfo[0]).toEqual(expect.objectContaining({
        element: element1,
        eventTypes: ['click'],
        listenerCount: 1
      }))
    })
  })
})