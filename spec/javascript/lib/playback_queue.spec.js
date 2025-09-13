import { PlaybackQueue } from '../../../app/frontend/lib/playback_queue'

describe('PlaybackQueue', () => {
  let queue

  beforeEach(() => {
    queue = new PlaybackQueue()
  })

  afterEach(() => {
    queue.clear()
  })

  describe('Queue management', () => {
    it('should initialize with empty queue', () => {
      expect(queue.isEmpty()).toBe(true)
      expect(queue.size()).toBe(0)
    })

    it('should add items to queue', () => {
      const item1 = { id: 1, action: 'play', track: { id: 1, title: 'Track 1' } }
      const item2 = { id: 2, action: 'pause' }

      queue.enqueue(item1)
      expect(queue.size()).toBe(1)
      expect(queue.isEmpty()).toBe(false)

      queue.enqueue(item2)
      expect(queue.size()).toBe(2)
    })

    it('should process items in FIFO order', async () => {
      const results = []
      const item1 = {
        id: 1,
        execute: jest.fn(() => {
          results.push('item1')
          return Promise.resolve()
        })
      }
      const item2 = {
        id: 2,
        execute: jest.fn(() => {
          results.push('item2')
          return Promise.resolve()
        })
      }

      queue.enqueue(item1)
      queue.enqueue(item2)

      await queue.process()

      expect(results).toEqual(['item1'])
      expect(item1.execute).toHaveBeenCalled()
      expect(item2.execute).not.toHaveBeenCalled()
      expect(queue.size()).toBe(1)
    })

    it('should clear queue', () => {
      queue.enqueue({ id: 1 })
      queue.enqueue({ id: 2 })
      queue.enqueue({ id: 3 })

      expect(queue.size()).toBe(3)

      queue.clear()
      expect(queue.size()).toBe(0)
      expect(queue.isEmpty()).toBe(true)
    })

    it('should peek at next item without removing it', () => {
      const item1 = { id: 1, action: 'play' }
      const item2 = { id: 2, action: 'pause' }

      queue.enqueue(item1)
      queue.enqueue(item2)

      expect(queue.peek()).toEqual(item1)
      expect(queue.size()).toBe(2) // Size unchanged
      expect(queue.peek()).toEqual(item1) // Can peek multiple times
    })
  })

  describe('Processing with AbortController', () => {
    it('should process item with AbortController', async () => {
      let abortSignal = null
      const item = {
        id: 1,
        execute: jest.fn((signal) => {
          abortSignal = signal
          return new Promise((resolve) => {
            setTimeout(resolve, 100)
          })
        })
      }

      queue.enqueue(item)
      const processPromise = queue.process()

      // Check that AbortController is created
      expect(queue.getCurrentAbortController()).not.toBeNull()

      await processPromise

      expect(item.execute).toHaveBeenCalledWith(expect.any(AbortSignal))
      expect(abortSignal).toBeInstanceOf(AbortSignal)
    })

    it('should abort current processing when requested', async () => {
      let isAborted = false
      const item = {
        id: 1,
        execute: jest.fn((signal) => {
          return new Promise((resolve, reject) => {
            signal.addEventListener('abort', () => {
              isAborted = true
              reject(new DOMException('Aborted', 'AbortError'))
            })
            // Simulate long-running task
            setTimeout(resolve, 1000)
          })
        })
      }

      queue.enqueue(item)
      const processPromise = queue.process()

      // Abort after a short delay
      setTimeout(() => queue.abort(), 50)

      await expect(processPromise).rejects.toThrow('Aborted')
      expect(isAborted).toBe(true)
    })

    it('should handle abort and continue with next item', async () => {
      const results = []
      const item1 = {
        id: 1,
        execute: jest.fn((signal) => {
          return new Promise((resolve, reject) => {
            signal.addEventListener('abort', () => {
              results.push('item1-aborted')
              reject(new DOMException('Aborted', 'AbortError'))
            })
            setTimeout(() => {
              results.push('item1-completed')
              resolve()
            }, 1000)
          })
        })
      }
      const item2 = {
        id: 2,
        execute: jest.fn(() => {
          results.push('item2-completed')
          return Promise.resolve()
        })
      }

      queue.enqueue(item1)
      queue.enqueue(item2)

      // Process first item
      const process1 = queue.process()
      setTimeout(() => queue.abort(), 50)

      try {
        await process1
      } catch (error) {
        expect(error.name).toBe('AbortError')
      }

      expect(results).toContain('item1-aborted')
      expect(queue.size()).toBe(1) // item1 removed, item2 remains

      // Process second item
      await queue.process()
      expect(results).toContain('item2-completed')
      expect(queue.isEmpty()).toBe(true)
    })
  })

  describe('Concurrent processing control', () => {
    it('should prevent concurrent processing', async () => {
      let processCount = 0
      const item1 = {
        id: 1,
        execute: jest.fn(async () => {
          processCount++
          await new Promise(resolve => setTimeout(resolve, 100))
        })
      }
      const item2 = {
        id: 2,
        execute: jest.fn(async () => {
          processCount++
        })
      }

      queue.enqueue(item1)
      queue.enqueue(item2)

      // Try to process concurrently
      const promise1 = queue.process()
      const promise2 = queue.process()

      await Promise.all([promise1, promise2])

      // Only one item should have been processed
      expect(processCount).toBe(1)
      expect(item1.execute).toHaveBeenCalledTimes(1)
      expect(item2.execute).not.toHaveBeenCalled()
    })

    it('should track processing state', async () => {
      const item = {
        id: 1,
        execute: jest.fn(() => {
          return new Promise(resolve => setTimeout(resolve, 50))
        })
      }

      queue.enqueue(item)
      expect(queue.isProcessing()).toBe(false)

      const processPromise = queue.process()
      expect(queue.isProcessing()).toBe(true)

      await processPromise
      expect(queue.isProcessing()).toBe(false)
    })
  })

  describe('Error handling', () => {
    it('should handle execution errors', async () => {
      const item = {
        id: 1,
        execute: jest.fn(() => Promise.reject(new Error('Execution failed')))
      }

      queue.enqueue(item)
      await expect(queue.process()).rejects.toThrow('Execution failed')

      // Item should be removed from queue even on error
      expect(queue.isEmpty()).toBe(true)
    })

    it('should handle missing execute method', async () => {
      const item = { id: 1 } // No execute method

      queue.enqueue(item)
      await expect(queue.process()).rejects.toThrow('Queue item must have an execute method')
    })

    it('should handle synchronous execute methods', async () => {
      const item = {
        id: 1,
        execute: jest.fn(() => 'sync-result') // Synchronous return
      }

      queue.enqueue(item)
      await queue.process()

      expect(item.execute).toHaveBeenCalled()
      expect(queue.isEmpty()).toBe(true)
    })
  })

  describe('Priority queue functionality', () => {
    it('should process high priority items first', async () => {
      const results = []
      const normalItem = {
        id: 1,
        priority: PlaybackQueue.PRIORITY.NORMAL,
        execute: jest.fn(() => {
          results.push('normal')
          return Promise.resolve()
        })
      }
      const highItem = {
        id: 2,
        priority: PlaybackQueue.PRIORITY.HIGH,
        execute: jest.fn(() => {
          results.push('high')
          return Promise.resolve()
        })
      }

      queue.enqueue(normalItem)
      queue.enqueue(highItem)

      // High priority should be processed first
      await queue.process()
      expect(results).toEqual(['high'])
    })

    it('should maintain FIFO order within same priority', async () => {
      const results = []
      const item1 = {
        id: 1,
        priority: PlaybackQueue.PRIORITY.HIGH,
        execute: () => {
          results.push('high1')
          return Promise.resolve()
        }
      }
      const item2 = {
        id: 2,
        priority: PlaybackQueue.PRIORITY.HIGH,
        execute: () => {
          results.push('high2')
          return Promise.resolve()
        }
      }

      queue.enqueue(item1)
      queue.enqueue(item2)

      await queue.process()
      expect(results).toEqual(['high1']) // First high priority item

      await queue.process()
      expect(results).toEqual(['high1', 'high2']) // Then second high priority item
    })
  })

  describe('Queue statistics', () => {
    it('should track processing statistics', async () => {
      const item = {
        id: 1,
        execute: () => new Promise(resolve => setTimeout(resolve, 50))
      }

      queue.enqueue(item)
      const stats = queue.getStats()

      expect(stats.totalEnqueued).toBe(1)
      expect(stats.totalProcessed).toBe(0)
      expect(stats.totalAborted).toBe(0)
      expect(stats.currentSize).toBe(1)

      await queue.process()

      const updatedStats = queue.getStats()
      expect(updatedStats.totalProcessed).toBe(1)
      expect(updatedStats.currentSize).toBe(0)
    })

    it('should track aborted items', async () => {
      const item = {
        id: 1,
        execute: (signal) => {
          return new Promise((resolve, reject) => {
            signal.addEventListener('abort', () => {
              reject(new DOMException('Aborted', 'AbortError'))
            })
            setTimeout(resolve, 1000)
          })
        }
      }

      queue.enqueue(item)
      const processPromise = queue.process()

      setTimeout(() => queue.abort(), 50)

      try {
        await processPromise
      } catch (error) {
        // Expected abort error
      }

      const stats = queue.getStats()
      expect(stats.totalAborted).toBe(1)
    })
  })
})