import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  
  connect() {
    this.setupResponsive()
    window.addEventListener('resize', this.handleResize.bind(this))
  }
  
  disconnect() {
    window.removeEventListener('resize', this.handleResize.bind(this))
  }
  
  toggleSidebar() {
    if (this.isMobile()) {
      this.showMobileSidebar()
    }
  }
  
  closeSidebar() {
    if (this.isMobile()) {
      this.hideMobileSidebar()
    }
  }
  
  handleResize() {
    if (!this.isMobile()) {
      this.hideMobileSidebar()
    }
  }
  
  // Private methods
  
  setupResponsive() {
    if (this.isMobile()) {
      this.hideMobileSidebar()
    }
  }
  
  showMobileSidebar() {
    this.sidebarTarget.classList.add('open')
    this.overlayTarget.style.display = 'block'
    document.body.classList.add('overflow-hidden')
  }
  
  hideMobileSidebar() {
    this.sidebarTarget.classList.remove('open')
    this.overlayTarget.style.display = 'none'
    document.body.classList.remove('overflow-hidden')
  }
  
  isMobile() {
    return window.innerWidth < 768
  }
}