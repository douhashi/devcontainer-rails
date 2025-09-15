import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  static values = { modalTarget: String }

  open(event) {
    event.preventDefault()
    const modalId = this.modalTargetValue
    const modal = document.getElementById(modalId)
    if (modal) {
      modal.classList.remove("hidden")
      document.body.style.overflow = "hidden"
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    const modal = this.modalTarget || this.element.closest('[data-modal-target="modal"]')
    if (modal) {
      modal.classList.add("hidden")
      document.body.style.overflow = ""
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnOutsideClick(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}