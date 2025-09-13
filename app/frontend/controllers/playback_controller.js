/**
 * PlaybackController - オーディオ再生制御のヘルパークラス
 * AbortController を使用した中断可能な再生制御とPromise-based制御を提供
 */
export class PlaybackController {
  constructor(audioElement) {
    this.audioElement = audioElement
    this.abortController = null
    this.isOperating = false
  }

  /**
   * 安全にオーディオを再生する
   * pause() → play() の順序で実行し、各操作の完了を適切に待機
   *
   * @param {boolean} shouldPause - 再生前にpause()を実行するか
   * @returns {Promise<void>}
   */
  async safePlay(shouldPause = true) {
    // 既存の操作がある場合は中断
    if (this.abortController) {
      this.abortController.abort()
    }

    // 新しいAbortControllerを作成
    this.abortController = new AbortController()
    const { signal } = this.abortController

    try {
      this.isOperating = true

      // AbortSignalをチェック
      if (signal.aborted) {
        throw new DOMException('Operation was aborted', 'AbortError')
      }

      // オーディオ要素の存在確認
      if (!this.audioElement) {
        throw new Error('Audio element not available')
      }

      // pause() が必要な場合は実行して完了を待機
      if (shouldPause && !this.audioElement.paused) {
        console.debug('[PlaybackController] Pausing current playback...')
        await this.safePause(signal)
      }

      // 再度AbortSignalをチェック
      if (signal.aborted) {
        throw new DOMException('Operation was aborted', 'AbortError')
      }

      // play() を実行
      console.debug('[PlaybackController] Starting playback...')
      await this.audioElement.play()

      console.debug('[PlaybackController] Playback started successfully')

    } catch (error) {
      // AbortErrorは想定内のエラーなので、詳細ログは出力しない
      if (error.name === 'AbortError') {
        console.debug('[PlaybackController] Playback operation was aborted')
      } else {
        console.error('[PlaybackController] Failed to play:', error)
      }
      throw error
    } finally {
      this.isOperating = false
    }
  }

  /**
   * 安全にオーディオを一時停止する
   * pause() の完了を Promise で待機
   *
   * @param {AbortSignal} signal - 中断用シグナル
   * @returns {Promise<void>}
   */
  async safePause(signal = null) {
    return new Promise((resolve, reject) => {
      if (signal && signal.aborted) {
        reject(new DOMException('Operation was aborted', 'AbortError'))
        return
      }

      if (this.audioElement.paused) {
        resolve()
        return
      }

      // pause完了を待機するためのイベントリスナー
      const handlePause = () => {
        this.audioElement.removeEventListener('pause', handlePause)
        resolve()
      }

      // AbortSignal処理
      const handleAbort = () => {
        this.audioElement.removeEventListener('pause', handlePause)
        reject(new DOMException('Operation was aborted', 'AbortError'))
      }

      if (signal) {
        signal.addEventListener('abort', handleAbort, { once: true })
      }

      this.audioElement.addEventListener('pause', handlePause, { once: true })

      // pause() を実行
      this.audioElement.pause()

      // タイムアウト処理（10秒でタイムアウト）
      setTimeout(() => {
        if (!this.audioElement.paused) {
          this.audioElement.removeEventListener('pause', handlePause)
          reject(new Error('Pause operation timed out'))
        }
      }, 10000)
    })
  }

  /**
   * 現在の操作を中断
   */
  abort() {
    if (this.abortController) {
      this.abortController.abort()
    }
  }

  /**
   * オーディオ要素の準備完了状態をチェック
   * @returns {boolean}
   */
  isReady() {
    return this.audioElement && this.audioElement.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA
  }

  /**
   * 操作中かどうかをチェック
   * @returns {boolean}
   */
  isBusy() {
    return this.isOperating
  }

  /**
   * クリーンアップ処理
   */
  cleanup() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
    this.audioElement = null
    this.isOperating = false
  }
}