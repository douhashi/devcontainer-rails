import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropZone", "fileInput", "form", "placeholder", "loading", "errorMessage", "thumbnailProgress"]
  
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

    // 画像サイズをチェックしてサムネイル生成対象か判定
    const isEligibleForThumbnail = await this.checkImageDimensions(file)
    if (isEligibleForThumbnail) {
      this.showThumbnailProgress()
    }

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
      this.hideThumbnailProgress()
    }
  }

  async checkImageDimensions(file) {
    return new Promise((resolve) => {
      const img = new Image()
      const url = URL.createObjectURL(file)

      img.onload = () => {
        URL.revokeObjectURL(url)
        // 1920x1080の場合のみサムネイル生成対象
        resolve(img.width === 1920 && img.height === 1080)
      }

      img.onerror = () => {
        URL.revokeObjectURL(url)
        resolve(false)
      }

      img.src = url
    })
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

  showThumbnailProgress() {
    if (this.hasThumbnailProgressTarget) {
      this.thumbnailProgressTarget.classList.remove('hidden')
      this.thumbnailProgressTarget.innerHTML = `
        <div class="flex items-center space-x-2">
          <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span class="text-sm text-gray-600">YouTube用サムネイルを生成中...</span>
        </div>
      `
    }
  }

  hideThumbnailProgress() {
    if (this.hasThumbnailProgressTarget) {
      this.thumbnailProgressTarget.classList.add('hidden')
    }
  }

  getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}