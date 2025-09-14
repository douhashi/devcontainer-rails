import { loadStimulusControllers, convertToControllerName } from './stimulus_loader'

describe('stimulus_loader', () => {
  describe('convertToControllerName', () => {
    it('単純なコントローラー名を変換する', () => {
      expect(convertToControllerName('layout_controller.js')).toBe('layout')
      expect(convertToControllerName('toast_controller.js')).toBe('toast')
    })

    it('複数の単語を含むコントローラー名をkebab-caseに変換する', () => {
      expect(convertToControllerName('delete_confirmation_controller.js')).toBe('delete-confirmation')
      expect(convertToControllerName('flash_message_controller.js')).toBe('flash-message')
      expect(convertToControllerName('form_validation_controller.js')).toBe('form-validation')
      expect(convertToControllerName('file_preview_controller.js')).toBe('file-preview')
    })

    it('3つ以上の単語を含むコントローラー名を変換する', () => {
      expect(convertToControllerName('inline_audio_player_controller.js')).toBe('inline-audio-player')
      expect(convertToControllerName('single_track_generation_controller.js')).toBe('single-track-generation')
      expect(convertToControllerName('audio_play_button_controller.js')).toBe('audio-play-button')
      expect(convertToControllerName('artwork_drag_drop_controller.js')).toBe('artwork-drag-drop')
    })

    it('_controller.jsサフィックスがない場合でも処理できる', () => {
      expect(convertToControllerName('layout')).toBe('layout')
      expect(convertToControllerName('delete_confirmation')).toBe('delete-confirmation')
    })

    it('パスを含むファイル名から正しく抽出する', () => {
      expect(convertToControllerName('./controllers/layout_controller.js')).toBe('layout')
      expect(convertToControllerName('../controllers/delete_confirmation_controller.js')).toBe('delete-confirmation')
      expect(convertToControllerName('/app/frontend/controllers/inline_audio_player_controller.js')).toBe('inline-audio-player')
    })

    it('不正な入力に対してエラーを処理する', () => {
      expect(convertToControllerName('')).toBe('')
      expect(convertToControllerName(null)).toBe('')
      expect(convertToControllerName(undefined)).toBe('')
    })
  })

  describe('loadStimulusControllers', () => {
    it('applicationにコントローラーを登録する', () => {
      const mockApplication = {
        register: jest.fn()
      }

      const mockModules = {
        './controllers/layout_controller.js': { default: class LayoutController {} },
        './controllers/delete_confirmation_controller.js': { default: class DeleteConfirmationController {} },
        './controllers/inline_audio_player_controller.js': { default: class InlineAudioPlayerController {} }
      }

      loadStimulusControllers(mockApplication, mockModules)

      expect(mockApplication.register).toHaveBeenCalledTimes(3)
      expect(mockApplication.register).toHaveBeenCalledWith('layout', expect.any(Function))
      expect(mockApplication.register).toHaveBeenCalledWith('delete-confirmation', expect.any(Function))
      expect(mockApplication.register).toHaveBeenCalledWith('inline-audio-player', expect.any(Function))
    })

    it('default exportがない場合はエラーログを出力してスキップする', () => {
      const mockApplication = {
        register: jest.fn()
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      const mockModules = {
        './controllers/layout_controller.js': { default: class LayoutController {} },
        './controllers/broken_controller.js': {}, // default exportなし
        './controllers/toast_controller.js': { default: class ToastController {} }
      }

      loadStimulusControllers(mockApplication, mockModules)

      expect(mockApplication.register).toHaveBeenCalledTimes(2)
      expect(mockApplication.register).toHaveBeenCalledWith('layout', expect.any(Function))
      expect(mockApplication.register).toHaveBeenCalledWith('toast', expect.any(Function))
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('No default export found for'),
        expect.stringContaining('broken_controller.js')
      )

      consoleErrorSpy.mockRestore()
    })

    it('登録時のエラーをキャッチしてログを出力する', () => {
      const mockApplication = {
        register: jest.fn().mockImplementation((name) => {
          if (name === 'error-controller') {
            throw new Error('Registration failed')
          }
        })
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      const mockModules = {
        './controllers/layout_controller.js': { default: class LayoutController {} },
        './controllers/error_controller.js': { default: class ErrorController {} },
        './controllers/toast_controller.js': { default: class ToastController {} }
      }

      loadStimulusControllers(mockApplication, mockModules)

      expect(mockApplication.register).toHaveBeenCalledTimes(3)
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('Failed to register controller'),
        expect.stringContaining('error-controller'),
        expect.any(Error)
      )

      consoleErrorSpy.mockRestore()
    })

    it('デバッグモードで登録情報をログ出力する', () => {
      const mockApplication = {
        register: jest.fn()
      }

      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {})

      const mockModules = {
        './controllers/layout_controller.js': { default: class LayoutController {} }
      }

      loadStimulusControllers(mockApplication, mockModules, true) // debugモードON

      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('Registering Stimulus controller'),
        expect.stringContaining('layout'),
        expect.stringContaining('layout_controller.js')
      )

      consoleLogSpy.mockRestore()
    })

    it('空のモジュールでもエラーにならない', () => {
      const mockApplication = {
        register: jest.fn()
      }

      loadStimulusControllers(mockApplication, {})

      expect(mockApplication.register).not.toHaveBeenCalled()
    })
  })
})