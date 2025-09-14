import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropZone", "fileInput", "form", "placeholder", "loading", "errorMessage"]
  
  connect() {
    this.preventDefaults = this.preventDefaults.bind(this)
    this.highlight = this.highlight.bind(this)
    this.unhighlight = this.unhighlight.bind(this)
    this.handleDrop = this.handleDrop.bind(this)
  }

  openFileDialog(e) {
    e.preventDefault()
    this.fileInputTarget.click()
  }

  handleFileSelect(e) {
    const files = e.target.files
    if (files && files.length > 0) {
      this.handleFiles(files)
    }
  }

  handleDragOver(e) {
    this.preventDefaults(e)
    this.highlight()
  }

  handleDragLeave(e) {
    this.preventDefaults(e)
    this.unhighlight()
  }

  handleDrop(e) {
    this.preventDefaults(e)
    this.unhighlight()

    const dt = e.dataTransfer
    const files = dt.files

    this.handleFiles(files)
  }

  handleFiles(files) {
    if (files.length === 0) return

    const file = files[0]
    
    // ファイル検証
    if (!this.validateFile(file)) {
      return
    }

    // アップロード処理
    this.uploadFile(file)
  }

  validateFile(file) {
    // 画像ファイルかチェック
    if (!file.type.startsWith('image/')) {
      this.showError('画像ファイルを選択してください')
      return false
    }

    // ファイルサイズチェック（10MB以下）
    const maxSize = 10 * 1024 * 1024 // 10MB
    if (file.size > maxSize) {
      this.showError('ファイルサイズは10MB以下にしてください')
      return false
    }

    // 対応形式チェック
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif']
    if (!allowedTypes.includes(file.type)) {
      this.showError('JPEG、PNG、GIF形式の画像を選択してください')
      return false
    }

    return true
  }

  async uploadFile(file) {
    // ローディング表示
    this.showLoading()

    const formData = new FormData()
    formData.append('artwork[image]', file)

    try {
      const response = await fetch(this.formTarget.action, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: formData
      })

      if (!response.ok) {
        throw new Error(`アップロードに失敗しました: ${response.statusText}`)
      }

      // Turbo Streamの処理を待つ
      const text = await response.text()
      if (text) {
        Turbo.renderStreamMessage(text)
      }
    } catch (error) {
      console.error('Upload error:', error)
      this.showError(error.message || 'アップロードに失敗しました')
      this.hideLoading()
    }
  }


  showLoading() {
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add('hidden')
    }
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove('hidden')
    }
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')
      
      // 5秒後にエラーメッセージを非表示
      setTimeout(() => {
        this.errorMessageTarget.classList.add('hidden')
      }, 5000)
    }
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight() {
    this.dropZoneTarget.classList.add('border-blue-500', 'bg-gray-750')
  }

  unhighlight() {
    this.dropZoneTarget.classList.remove('border-blue-500', 'bg-gray-750')
  }


  getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}