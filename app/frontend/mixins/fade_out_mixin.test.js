import FadeOutMixin from './fade_out_mixin'
import { Controller } from "@hotwired/stimulus"

describe('FadeOutMixin', () => {
  let controller
  let element
  
  beforeEach(() => {
    jest.useFakeTimers()
    
    element = document.createElement('div')
    element.setAttribute('data-controller', 'test')
    element.setAttribute('data-test-duration-value', '3000')
    document.body.appendChild(element)
    
    class TestController extends Controller {
      static values = { duration: Number }
    }
    
    Object.assign(TestController.prototype, FadeOutMixin)
    
    controller = new TestController()
    controller.element = element
    controller.durationValue = 3000
    controller.hasDurationValue = true
  })
  
  afterEach(() => {
    jest.clearAllTimers()
    jest.useRealTimers()
    document.body.removeChild(element)
  })
  
  describe('setupAutoClose', () => {
    it('should set up auto close timeout when duration is provided', () => {
      controller.setupAutoClose()
      
      expect(controller.autoCloseTimeout).toBeDefined()
      
      jest.advanceTimersByTime(3000)
      
      expect(element.classList.contains('opacity-0')).toBe(true)
    })
    
    it('should not set up timeout when duration is 0', () => {
      controller.durationValue = 0
      controller.setupAutoClose()
      
      expect(controller.autoCloseTimeout).toBeUndefined()
    })
    
    it('should not set up timeout when duration is not provided', () => {
      controller.hasDurationValue = false
      controller.setupAutoClose()
      
      expect(controller.autoCloseTimeout).toBeUndefined()
    })
  })
  
  describe('fadeOut', () => {
    it('should add fade out classes and remove element after transition', () => {
      const removeSpy = jest.spyOn(element, 'remove')
      
      controller.fadeOut()
      
      expect(element.classList.contains('opacity-0')).toBe(true)
      expect(element.classList.contains('transition-opacity')).toBe(true)
      expect(element.style.transitionDuration).toBe('300ms')
      
      jest.advanceTimersByTime(300)
      
      expect(removeSpy).toHaveBeenCalled()
    })
    
    it('should accept custom duration', () => {
      const removeSpy = jest.spyOn(element, 'remove')
      
      controller.fadeOut(500)
      
      expect(element.classList.contains('opacity-0')).toBe(true)
      expect(element.classList.contains('transition-opacity')).toBe(true)
      expect(element.style.transitionDuration).toBe('500ms')
      
      jest.advanceTimersByTime(500)
      
      expect(removeSpy).toHaveBeenCalled()
    })
  })
  
  describe('cleanupTimeout', () => {
    it('should clear auto close timeout if it exists', () => {
      controller.setupAutoClose()
      
      expect(controller.autoCloseTimeout).toBeDefined()
      
      controller.cleanupTimeout()
      
      jest.advanceTimersByTime(3000)
      
      expect(element.classList.contains('opacity-0')).toBe(false)
    })
    
    it('should handle cleanup when no timeout exists', () => {
      expect(() => controller.cleanupTimeout()).not.toThrow()
    })
  })
  
  describe('integration', () => {
    it('should work with close method', () => {
      controller.close = function() {
        this.cleanupTimeout()
        this.fadeOut()
      }
      
      controller.setupAutoClose()
      controller.close()
      
      expect(element.classList.contains('opacity-0')).toBe(true)
      
      jest.advanceTimersByTime(3000)
      
      expect(element.classList.contains('opacity-0')).toBe(true)
    })
  })
})