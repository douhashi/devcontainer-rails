import ErrorHandlingMixin from './error_handling_mixin'
import { Controller } from "@hotwired/stimulus"

describe('ErrorHandlingMixin', () => {
  let controller
  let element
  let consoleErrorSpy
  
  beforeEach(() => {
    jest.useFakeTimers()
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation()
    
    element = document.createElement('div')
    element.setAttribute('data-controller', 'test')
    document.body.appendChild(element)
    
    class TestController extends Controller {}
    
    Object.assign(TestController.prototype, ErrorHandlingMixin)
    
    controller = new TestController()
    controller.element = element
  })
  
  afterEach(() => {
    jest.clearAllTimers()
    jest.useRealTimers()
    consoleErrorSpy.mockRestore()
    document.body.removeChild(element)
  })
  
  describe('showError', () => {
    it('should display error message', () => {
      controller.showError('Test error message')
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement).toBeTruthy()
      expect(errorElement.textContent).toBe('Test error message')
    })
    
    it('should log error to console', () => {
      controller.showError('Test error message')
      
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error:', 'Test error message')
    })
    
    it('should apply error styles', () => {
      controller.showError('Test error message')
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement.classList.contains('bg-red-100')).toBe(true)
      expect(errorElement.classList.contains('border-red-400')).toBe(true)
      expect(errorElement.classList.contains('text-red-700')).toBe(true)
    })
    
    it('should auto-remove error after timeout', () => {
      controller.showError('Test error message', { autoRemove: true, timeout: 5000 })
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement).toBeTruthy()
      
      jest.advanceTimersByTime(5000)
      
      expect(element.querySelector('.error-message')).toBeFalsy()
    })
    
    it('should not auto-remove if autoRemove is false', () => {
      controller.showError('Test error message', { autoRemove: false })
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement).toBeTruthy()
      
      jest.advanceTimersByTime(10000)
      
      expect(element.querySelector('.error-message')).toBeTruthy()
    })
  })
  
  describe('clearErrors', () => {
    it('should remove all error messages', () => {
      controller.showError('Error 1')
      controller.showError('Error 2')
      
      expect(element.querySelectorAll('.error-message').length).toBe(2)
      
      controller.clearErrors()
      
      expect(element.querySelectorAll('.error-message').length).toBe(0)
    })
  })
  
  describe('handleError', () => {
    it('should handle Error objects', () => {
      const error = new Error('Test error')
      controller.handleError(error)
      
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error:', 'Test error')
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement.textContent).toBe('Test error')
    })
    
    it('should handle string errors', () => {
      controller.handleError('String error')
      
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error:', 'String error')
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement.textContent).toBe('String error')
    })
    
    it('should provide default message for unknown errors', () => {
      controller.handleError(null)
      
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error:', 'An unexpected error occurred')
      
      const errorElement = element.querySelector('.error-message')
      expect(errorElement.textContent).toBe('An unexpected error occurred')
    })
  })
})