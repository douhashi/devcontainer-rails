/**
 * AudioEventManager - イベントリスナーの統一管理クラス
 * WeakMapを使用してメモリリークを防ぎ、イベントリスナーを効率的に管理
 */
export class AudioEventManager {
  constructor() {
    // WeakMap for automatic garbage collection
    this._elementListeners = new WeakMap()
    // Track all elements for cleanup (WeakSet doesn't support iteration)
    this._trackedElements = new Set()
  }

  /**
   * Add event listener to element
   * @param {Element} element
   * @param {string} eventType
   * @param {Function} listener
   * @param {Object} options
   */
  addListener(element, eventType, listener, options = {}) {
    // Validate parameters
    if (!element || !(element instanceof Element || element instanceof Document)) {
      throw new Error('Element must be a valid DOM element')
    }
    if (typeof listener !== 'function') {
      throw new Error('Listener must be a function')
    }

    // Get or create listener map for element
    if (!this._elementListeners.has(element)) {
      this._elementListeners.set(element, new Map())
      this._trackedElements.add(element)
    }

    const elementMap = this._elementListeners.get(element)

    // Get or create listener set for event type
    if (!elementMap.has(eventType)) {
      elementMap.set(eventType, new Set())
    }

    const listeners = elementMap.get(eventType)

    // Store listener info
    const listenerInfo = {
      listener,
      options,
      wrapped: this._wrapListener(listener)
    }

    listeners.add(listenerInfo)

    // Add actual event listener
    element.addEventListener(eventType, listenerInfo.wrapped, options)
  }

  /**
   * Remove event listener from element
   * @param {Element} element
   * @param {string} eventType
   * @param {Function} listener
   */
  removeListener(element, eventType, listener) {
    if (!this._elementListeners.has(element)) {
      return
    }

    const elementMap = this._elementListeners.get(element)

    if (!elementMap.has(eventType)) {
      return
    }

    const listeners = elementMap.get(eventType)

    // Find and remove listener
    for (const listenerInfo of listeners) {
      if (listenerInfo.listener === listener) {
        element.removeEventListener(eventType, listenerInfo.wrapped, listenerInfo.options)
        listeners.delete(listenerInfo)
        break
      }
    }

    // Clean up empty sets
    if (listeners.size === 0) {
      elementMap.delete(eventType)
    }
  }

  /**
   * Remove all listeners for specific event type on element
   * @param {Element} element
   * @param {string} eventType
   */
  removeEventListeners(element, eventType) {
    if (!this._elementListeners.has(element)) {
      return
    }

    const elementMap = this._elementListeners.get(element)

    if (!elementMap.has(eventType)) {
      return
    }

    const listeners = elementMap.get(eventType)

    // Remove all listeners for this event type
    for (const listenerInfo of listeners) {
      element.removeEventListener(eventType, listenerInfo.wrapped, listenerInfo.options)
    }

    elementMap.delete(eventType)
  }

  /**
   * Remove all listeners for element
   * @param {Element} element
   */
  removeAllListeners(element) {
    if (!this._elementListeners.has(element)) {
      return
    }

    const elementMap = this._elementListeners.get(element)

    // Remove all listeners for all event types
    for (const [eventType, listeners] of elementMap) {
      for (const listenerInfo of listeners) {
        element.removeEventListener(eventType, listenerInfo.wrapped, listenerInfo.options)
      }
    }

    this._elementListeners.delete(element)
    this._trackedElements.delete(element)
  }

  /**
   * Check if element has listeners
   * @param {Element} element
   * @returns {boolean}
   */
  hasListeners(element) {
    return this._elementListeners.has(element)
  }

  /**
   * Dispatch custom event
   * @param {Element} element
   * @param {string} eventType
   * @param {Object} detail
   */
  dispatchCustomEvent(element, eventType, detail = {}) {
    const event = new CustomEvent(eventType, {
      detail,
      bubbles: true,
      cancelable: true
    })

    element.dispatchEvent(event)
  }

  /**
   * Dispatch audio-specific event on document
   * @param {string} eventName
   * @param {Object} detail
   */
  dispatchAudioEvent(eventName, detail = {}) {
    this.dispatchCustomEvent(document, `audio:${eventName}`, detail)
  }

  /**
   * Get statistics about managed listeners
   * @returns {Object}
   */
  getStats() {
    const stats = {
      totalElements: this._trackedElements.size,
      totalListeners: 0,
      byElement: {}
    }

    for (const element of this._trackedElements) {
      if (!this._elementListeners.has(element)) {
        continue
      }

      const elementMap = this._elementListeners.get(element)
      const tagName = element.tagName || 'DOCUMENT'

      let elementStats = {
        events: elementMap.size,
        listeners: 0
      }

      for (const listeners of elementMap.values()) {
        elementStats.listeners += listeners.size
        stats.totalListeners += listeners.size
      }

      stats.byElement[tagName] = elementStats
    }

    return stats
  }

  /**
   * Get debug information
   * @returns {Array}
   */
  getDebugInfo() {
    const debugInfo = []

    for (const element of this._trackedElements) {
      if (!this._elementListeners.has(element)) {
        continue
      }

      const elementMap = this._elementListeners.get(element)
      const eventTypes = Array.from(elementMap.keys())

      let listenerCount = 0
      for (const listeners of elementMap.values()) {
        listenerCount += listeners.size
      }

      debugInfo.push({
        element,
        eventTypes,
        listenerCount
      })
    }

    return debugInfo
  }

  /**
   * Cleanup all listeners
   */
  cleanup() {
    // Remove all listeners from all tracked elements
    for (const element of this._trackedElements) {
      this.removeAllListeners(element)
    }

    this._trackedElements.clear()
  }

  /**
   * Wrap listener with error handling
   * @private
   * @param {Function} listener
   * @returns {Function}
   */
  _wrapListener(listener) {
    return function wrappedListener(event) {
      try {
        listener.call(this, event)
      } catch (error) {
        console.error('Error in event listener:', error)
      }
    }
  }
}