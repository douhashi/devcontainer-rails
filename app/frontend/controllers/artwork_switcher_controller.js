import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "thumbnail"]
  static values = { animating: Boolean }

  connect() {
    this.initializeSelectedThumbnail()
    this.setupMainImageTransition()
    this.animatingValue = false
  }

  // 画像切り替えアクション
  switchImage(event) {
    // アニメーション中はクリックを無効化
    if (this.animatingValue) {
      return
    }

    const clickedThumbnail = event.currentTarget
    const imageUrl = clickedThumbnail.dataset.imageUrl
    const imageType = clickedThumbnail.dataset.imageType

    // プレースホルダーの場合は切り替えない
    if (imageType === "youtube_placeholder") {
      console.info("Cannot switch to placeholder image")
      return
    }

    if (!imageUrl) {
      console.warn("No image URL found for thumbnail")
      return
    }

    // 既に選択されている画像の場合は何もしない
    if (clickedThumbnail.classList.contains("ring-blue-500")) {
      return
    }

    this.updateMainImage(imageUrl)
    this.updateSelectedThumbnail(clickedThumbnail)
  }

  // メイン画像を更新
  updateMainImage(imageUrl) {
    if (!this.hasMainImageTarget) return

    this.animatingValue = true

    // 画像をプリロード
    const newImage = new Image()

    newImage.onload = () => {
      // クロスフェードアニメーション
      this.mainImageTarget.classList.add("opacity-0")

      // アニメーション完了後に画像を切り替え
      setTimeout(() => {
        this.mainImageTarget.src = imageUrl
        // 少し遅延してからフェードイン
        requestAnimationFrame(() => {
          this.mainImageTarget.classList.remove("opacity-0")
          // アニメーション完了後にフラグをリセット
          setTimeout(() => {
            this.animatingValue = false
          }, 300)
        })
      }, 150)
    }

    newImage.onerror = () => {
      console.error("Failed to load image:", imageUrl)
      this.animatingValue = false
    }

    newImage.src = imageUrl
  }

  // メイン画像にトランジションを設定
  setupMainImageTransition() {
    if (this.hasMainImageTarget) {
      this.mainImageTarget.classList.add("transition-opacity", "duration-300", "ease-in-out")
    }
  }

  // 選択されたサムネイルの状態を更新
  updateSelectedThumbnail(selectedThumbnail) {
    // 全てのサムネイルから選択状態を削除
    this.thumbnailTargets.forEach(thumbnail => {
      // プレースホルダーはスキップ
      if (thumbnail.dataset.imageType === "youtube_placeholder") {
        return
      }

      // 選択状態を解除
      thumbnail.classList.remove(
        "ring-2", "ring-blue-500", "bg-blue-50", "shadow-lg", "scale-105"
      )
      // 非選択状態のスタイルを適用
      thumbnail.classList.add(
        "opacity-75", "hover:opacity-100",
        "hover:ring-2", "hover:ring-blue-300",
        "hover:scale-105", "hover:shadow-xl",
        "transition-all", "duration-200"
      )
    })

    // 選択されたサムネイルに選択状態のスタイルを適用
    selectedThumbnail.classList.add(
      "ring-2", "ring-blue-500", "bg-blue-50", "shadow-lg", "scale-105"
    )
    selectedThumbnail.classList.remove(
      "opacity-75", "hover:opacity-100",
      "hover:ring-2", "hover:ring-blue-300",
      "hover:scale-105", "hover:shadow-xl"
    )

    // ARIA属性を更新
    this.thumbnailTargets.forEach(thumbnail => {
      thumbnail.setAttribute("aria-selected", "false")
    })
    selectedThumbnail.setAttribute("aria-selected", "true")
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
    const currentThumbnail = event.currentTarget
    const thumbnails = this.thumbnailTargets.filter(
      t => t.dataset.imageType !== "youtube_placeholder"
    )
    const currentIndex = thumbnails.indexOf(currentThumbnail)

    switch(event.key) {
      case "Enter":
      case " ":
        event.preventDefault()
        this.switchImage(event)
        break
      case "ArrowRight":
      case "ArrowDown":
        event.preventDefault()
        const nextIndex = (currentIndex + 1) % thumbnails.length
        thumbnails[nextIndex].focus()
        break
      case "ArrowLeft":
      case "ArrowUp":
        event.preventDefault()
        const prevIndex = (currentIndex - 1 + thumbnails.length) % thumbnails.length
        thumbnails[prevIndex].focus()
        break
    }
  }

  // Turbo Frame更新後の状態復元
  turboFrameRestoreState() {
    // Turbo Frameによる更新後に選択状態を復元
    setTimeout(() => {
      this.initializeSelectedThumbnail()
      this.setupMainImageTransition()
    }, 100)
  }
}