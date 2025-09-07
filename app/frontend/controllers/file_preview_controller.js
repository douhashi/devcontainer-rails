import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "previewContainer"]

  preview(event) {
    const file = event.target.files[0]
    
    if (!file) {
      this.hidePreview()
      return
    }

    if (!file.type.startsWith('image/')) {
      this.hidePreview()
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.showPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  showPreview(src) {
    this.previewTarget.src = src
    this.previewContainerTarget.classList.remove("hidden")
  }

  hidePreview() {
    this.previewTarget.src = ""
    this.previewContainerTarget.classList.add("hidden")
  }
}