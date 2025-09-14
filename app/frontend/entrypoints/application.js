import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo-rails'
import 'media-chrome'
import '@fortawesome/fontawesome-free/css/all.css'

const application = Application.start()

// Import all Stimulus controllers manually
import LayoutController from '../controllers/layout_controller'
import DeleteConfirmationController from '../controllers/delete_confirmation_controller'
import FlashMessageController from '../controllers/flash_message_controller'
import FormValidationController from '../controllers/form_validation_controller'
import FilePreviewController from '../controllers/file_preview_controller'
import TrackGenerationController from '../controllers/track_generation_controller'
import StatusFilterController from '../controllers/status_filter_controller'
import SingleTrackGenerationController from '../controllers/single_track_generation_controller'
import AudioPlayerController from '../controllers/audio_player_controller'
import ArtworkDragDropController from '../controllers/artwork_drag_drop_controller'
import AudioPlayButtonController from '../controllers/audio_play_button_controller'
import ToastController from '../controllers/toast_controller'
import AudioGenerationController from '../controllers/audio_generation_controller'
import UserDropdownController from '../controllers/user_dropdown_controller'
import InlineAudioPlayerController from '../controllers/inline_audio_player_controller'

// Import global store and audio state management
import { AudioStateManager } from '../lib/audio_state_manager'

// Initialize AudioStateManager singleton
const audioStateManager = AudioStateManager.getInstance()

// Make it available globally for debugging (optional)
if (typeof window !== 'undefined') {
  window.audioStateManager = audioStateManager
}

application.register('layout', LayoutController)
application.register('delete-confirmation', DeleteConfirmationController)
application.register('flash-message', FlashMessageController)
application.register('form-validation', FormValidationController)
application.register('file-preview', FilePreviewController)
application.register('track-generation', TrackGenerationController)
application.register('status-filter', StatusFilterController)
application.register('single-track-generation', SingleTrackGenerationController)
application.register('audio-player', AudioPlayerController)
application.register('artwork-drag-drop', ArtworkDragDropController)
application.register('audio-play-button', AudioPlayButtonController)
application.register('toast', ToastController)
application.register('audio-generation', AudioGenerationController)
application.register('user-dropdown', UserDropdownController)
application.register('inline-audio-player', InlineAudioPlayerController)

console.log('Vite ⚡️ Rails with Stimulus & Turbo ready')
