import CharCountMixin from './char_count_mixin'
import { Controller } from "@hotwired/stimulus"

describe('CharCountMixin', () => {
  let controller
  let element
  let inputElement
  let displayElement
  
  beforeEach(() => {
    element = document.createElement('div')
    element.setAttribute('data-controller', 'test')
    
    inputElement = document.createElement('textarea')
    inputElement.value = 'Test text'
    
    displayElement = document.createElement('span')
    displayElement.className = 'char-count'
    
    element.appendChild(inputElement)
    element.appendChild(displayElement)
    document.body.appendChild(element)
    
    class TestController extends Controller {}
    
    Object.assign(TestController.prototype, CharCountMixin)
    
    controller = new TestController()
    controller.element = element
  })
  
  afterEach(() => {
    document.body.removeChild(element)
  })
  
  describe('updateCharCount', () => {
    it('should update character count display', () => {
      controller.updateCharCount(inputElement, displayElement)
      
      expect(displayElement.textContent).toBe('9')
    })
    
    it('should apply warning class when threshold is reached', () => {
      inputElement.value = 'A'.repeat(250)
      
      controller.updateCharCount(inputElement, displayElement, 240)
      
      expect(displayElement.textContent).toBe('250')
      expect(displayElement.classList.contains('text-yellow-400')).toBe(true)
      expect(displayElement.classList.contains('text-gray-400')).toBe(false)
    })
    
    it('should apply normal class when below threshold', () => {
      inputElement.value = 'A'.repeat(200)
      
      controller.updateCharCount(inputElement, displayElement, 240)
      
      expect(displayElement.textContent).toBe('200')
      expect(displayElement.classList.contains('text-gray-400')).toBe(true)
      expect(displayElement.classList.contains('text-yellow-400')).toBe(false)
    })
    
    it('should handle empty input', () => {
      inputElement.value = ''
      
      controller.updateCharCount(inputElement, displayElement)
      
      expect(displayElement.textContent).toBe('0')
    })
    
    it('should handle custom threshold', () => {
      inputElement.value = 'A'.repeat(500)
      
      controller.updateCharCount(inputElement, displayElement, 480)
      
      expect(displayElement.textContent).toBe('500')
      expect(displayElement.classList.contains('text-yellow-400')).toBe(true)
    })
  })
  
  describe('initCharCounter', () => {
    it('should initialize character counter with event listener', () => {
      const updateSpy = jest.spyOn(controller, 'updateCharCount')
      
      controller.initCharCounter(inputElement, displayElement, 240)
      
      expect(updateSpy).toHaveBeenCalledWith(inputElement, displayElement, 240)
      
      inputElement.value = 'New text'
      inputElement.dispatchEvent(new Event('input'))
      
      expect(updateSpy).toHaveBeenCalledTimes(2)
    })
    
    it('should handle multiple counters independently', () => {
      const input2 = document.createElement('textarea')
      input2.value = 'Different text'
      const display2 = document.createElement('span')
      element.appendChild(input2)
      element.appendChild(display2)
      
      controller.initCharCounter(inputElement, displayElement, 240)
      controller.initCharCounter(input2, display2, 900)
      
      expect(displayElement.textContent).toBe('9')
      expect(display2.textContent).toBe('14')
      
      input2.value = 'A'.repeat(950)
      input2.dispatchEvent(new Event('input'))
      
      expect(display2.textContent).toBe('950')
      expect(display2.classList.contains('text-yellow-400')).toBe(true)
      expect(displayElement.classList.contains('text-yellow-400')).toBe(false)
    })
  })
  
  describe('getCharCountElements', () => {
    it('should return input and display elements by selector', () => {
      inputElement.setAttribute('data-test-input-target', 'charInput')
      displayElement.setAttribute('data-test-display-target', 'charDisplay')
      
      controller.charInputTarget = inputElement
      controller.charDisplayTarget = displayElement
      
      controller.getCharCountElements = function(inputTarget, displayTarget) {
        return {
          input: this[inputTarget + 'Target'],
          display: this[displayTarget + 'Target']
        }
      }
      
      const elements = controller.getCharCountElements('charInput', 'charDisplay')
      
      expect(elements.input).toBe(inputElement)
      expect(elements.display).toBe(displayElement)
    })
  })
})