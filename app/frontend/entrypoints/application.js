import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo-rails'
import 'plyr/dist/plyr.css'

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

console.log('Vite ⚡️ Rails with Stimulus & Turbo ready')
