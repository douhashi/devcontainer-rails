/**
 * Stimulusコントローラーを自動的に読み込み、登録するヘルパー関数
 * Viteのimport.meta.glob()を使用して動的importを実現
 */

/**
 * ファイル名からStimulusコントローラー名に変換する
 * 例:
 *   - "layout_controller.js" -> "layout"
 *   - "delete_confirmation_controller.js" -> "delete-confirmation"
 *   - "./controllers/inline_audio_player_controller.js" -> "inline-audio-player"
 *
 * @param {string} filename - コントローラーファイル名またはパス
 * @returns {string} Stimulusコントローラー名（kebab-case）
 */
export function convertToControllerName(filename) {
  if (!filename || typeof filename !== 'string') {
    return ''
  }

  // パスからファイル名だけを抽出
  const basename = filename.split('/').pop()

  // _controller.jsを削除
  const name = basename.replace(/_controller\.js$/, '')

  // snake_caseからkebab-caseに変換
  return name.replace(/_/g, '-')
}

/**
 * 指定されたモジュールからStimulusコントローラーを読み込んで登録する
 *
 * @param {Application} application - Stimulus Application インスタンス
 * @param {Object} modules - import.meta.glob()で取得したモジュール
 * @param {boolean} debug - デバッグモード（詳細ログを出力）
 */
export function loadStimulusControllers(application, modules, debug = false) {
  for (const path in modules) {
    const module = modules[path]

    // コントローラー名を生成
    const controllerName = convertToControllerName(path)

    if (!controllerName) {
      console.error(`Failed to extract controller name from path: ${path}`)
      continue
    }

    // default exportを確認
    if (!module.default) {
      console.error(`No default export found for ${path}`)
      continue
    }

    try {
      // コントローラーを登録
      application.register(controllerName, module.default)

      if (debug) {
        console.log(`Registering Stimulus controller: ${controllerName} from ${path}`)
      }
    } catch (error) {
      console.error(`Failed to register controller ${controllerName}:`, error)
    }
  }
}

/**
 * Viteのimport.meta.glob()を使用してコントローラーを自動読み込み
 *
 * @param {Application} application - Stimulus Application インスタンス
 * @param {boolean} debug - デバッグモード（詳細ログを出力）
 */
export function autoLoadControllers(application, debug = false) {
  // Viteのimport.meta.glob()でcontrollersディレクトリの全てのコントローラーを読み込み
  // eager: trueで即座に全てを読み込む（コントローラー数が限られているため）
  const modules = import.meta.glob('../controllers/*_controller.js', { eager: true })

  if (debug) {
    console.log(`Found ${Object.keys(modules).length} Stimulus controllers`)
  }

  loadStimulusControllers(application, modules, debug)
}