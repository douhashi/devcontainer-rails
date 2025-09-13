/**
 * PlaybackQueue - オーディオ再生リクエストのキューイング管理
 * 優先度付きキューとAbortControllerによる中断可能な処理を提供
 */
export class PlaybackQueue {
  // Priority levels
  static PRIORITY = Object.freeze({
    HIGH: 1,
    NORMAL: 2,
    LOW: 3
  })

  constructor() {
    this._queue = []
    this._isProcessing = false
    this._currentAbortController = null
    this._stats = {
      totalEnqueued: 0,
      totalProcessed: 0,
      totalAborted: 0
    }
  }

  /**
   * Add item to queue
   * @param {Object} item - Queue item with execute method
   */
  enqueue(item) {
    // Set default priority if not specified
    if (!item.priority) {
      item.priority = PlaybackQueue.PRIORITY.NORMAL
    }

    this._queue.push(item)
    this._stats.totalEnqueued++

    // Sort queue by priority (lower number = higher priority)
    this._sortQueue()
  }

  /**
   * Process next item in queue
   * @returns {Promise}
   */
  async process() {
    // Prevent concurrent processing
    if (this._isProcessing) {
      console.debug('[PlaybackQueue] Already processing, skipping')
      return
    }

    if (this.isEmpty()) {
      console.debug('[PlaybackQueue] Queue is empty')
      return
    }

    this._isProcessing = true

    // Get next item
    const item = this._dequeue()

    // Validate item has execute method
    if (!item.execute || typeof item.execute !== 'function') {
      this._isProcessing = false
      throw new Error('Queue item must have an execute method')
    }

    // Create new AbortController for this operation
    this._currentAbortController = new AbortController()
    const { signal } = this._currentAbortController

    try {
      // Execute item with abort signal
      const result = await Promise.resolve(item.execute(signal))

      // Update stats on success
      this._stats.totalProcessed++

      return result
    } catch (error) {
      // Track aborted operations
      if (error.name === 'AbortError') {
        this._stats.totalAborted++
      }
      throw error
    } finally {
      this._isProcessing = false
      this._currentAbortController = null
    }
  }

  /**
   * Abort current processing
   */
  abort() {
    if (this._currentAbortController) {
      this._currentAbortController.abort()
    }
  }

  /**
   * Clear all items from queue
   */
  clear() {
    this._queue = []
  }

  /**
   * Check if queue is empty
   * @returns {boolean}
   */
  isEmpty() {
    return this._queue.length === 0
  }

  /**
   * Get queue size
   * @returns {number}
   */
  size() {
    return this._queue.length
  }

  /**
   * Peek at next item without removing
   * @returns {Object|null}
   */
  peek() {
    return this._queue[0] || null
  }

  /**
   * Check if currently processing
   * @returns {boolean}
   */
  isProcessing() {
    return this._isProcessing
  }

  /**
   * Get current abort controller
   * @returns {AbortController|null}
   */
  getCurrentAbortController() {
    return this._currentAbortController
  }

  /**
   * Get queue statistics
   * @returns {Object}
   */
  getStats() {
    return {
      totalEnqueued: this._stats.totalEnqueued,
      totalProcessed: this._stats.totalProcessed,
      totalAborted: this._stats.totalAborted,
      currentSize: this.size(),
      isProcessing: this._isProcessing
    }
  }

  /**
   * Remove and return next item from queue
   * @private
   * @returns {Object|null}
   */
  _dequeue() {
    return this._queue.shift()
  }

  /**
   * Sort queue by priority
   * @private
   */
  _sortQueue() {
    this._queue.sort((a, b) => {
      // Sort by priority (lower number = higher priority)
      const priorityDiff = (a.priority || PlaybackQueue.PRIORITY.NORMAL) -
                           (b.priority || PlaybackQueue.PRIORITY.NORMAL)

      if (priorityDiff !== 0) {
        return priorityDiff
      }

      // If same priority, maintain FIFO order
      // Items already in queue maintain their relative order
      return 0
    })
  }
}