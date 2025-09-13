import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "thumbnail"]

  connect() {
    this.initializeSelectedThumbnail()
  }

  // 画像切り替えアクション
  switchImage(event) {
    const clickedThumbnail = event.currentTarget
    const imageUrl = clickedThumbnail.dataset.imageUrl
    const imageType = clickedThumbnail.dataset.imageType

    if (!imageUrl) {
      console.warn("No image URL found for thumbnail")
      return
    }

    this.updateMainImage(imageUrl)
    this.updateSelectedThumbnail(clickedThumbnail)
  }

  // メイン画像を更新
  updateMainImage(imageUrl) {
    if (this.hasMainImageTarget) {
      // フェード効果でスムーズに切り替え
      this.mainImageTarget.style.opacity = "0.5"

      // 新しい画像をロード
      const newImage = new Image()
      newImage.onload = () => {
        this.mainImageTarget.src = imageUrl
        this.mainImageTarget.style.opacity = "1"
      }
      newImage.onerror = () => {
        console.error("Failed to load image:", imageUrl)
        this.mainImageTarget.style.opacity = "1"
      }
      newImage.src = imageUrl
    }
  }

  // 選択されたサムネイルの状態を更新
  updateSelectedThumbnail(selectedThumbnail) {
    // 全てのサムネイルから選択状態を削除
    this.thumbnailTargets.forEach(thumbnail => {
      thumbnail.classList.remove("ring-2", "ring-blue-500", "bg-blue-50")
      thumbnail.classList.add("hover:ring-2", "hover:ring-blue-300", "transition-all")
    })

    // 選択されたサムネイルに選択状態のスタイルを適用
    selectedThumbnail.classList.add("ring-2", "ring-blue-500", "bg-blue-50")
    selectedThumbnail.classList.remove("hover:ring-2", "hover:ring-blue-300")
  }

  // 初期化時にデフォルトの選択状態を設定
  initializeSelectedThumbnail() {
    // オリジナル画像（image-type="original"）をデフォルトで選択
    const originalThumbnail = this.thumbnailTargets.find(
      thumbnail => thumbnail.dataset.imageType === "original"
    )

    if (originalThumbnail) {
      this.updateSelectedThumbnail(originalThumbnail)
    }
  }

  // キーボードサポート
  handleKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.switchImage(event)
    }
  }

  // Turbo Frame更新後の状態復元
  turboFrameRestoreState() {
    // Turbo Frameによる更新後に選択状態を復元
    setTimeout(() => {
      this.initializeSelectedThumbnail()
    }, 100)
  }
}