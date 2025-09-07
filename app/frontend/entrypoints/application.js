import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo-rails'

const application = Application.start()

// Import all Stimulus controllers manually
import LayoutController from '../controllers/layout_controller'
import DeleteConfirmationController from '../controllers/delete_confirmation_controller'
import FlashMessageController from '../controllers/flash_message_controller'
import FormValidationController from '../controllers/form_validation_controller'
import FilePreviewController from '../controllers/file_preview_controller'
import TrackGenerationController from '../controllers/track_generation_controller'
import StatusFilterController from '../controllers/status_filter_controller'

application.register('layout', LayoutController)
application.register('delete-confirmation', DeleteConfirmationController)
application.register('flash-message', FlashMessageController)
application.register('form-validation', FormValidationController)
application.register('file-preview', FilePreviewController)
application.register('track-generation', TrackGenerationController)
application.register('status-filter', StatusFilterController)

console.log('Vite ⚡️ Rails with Stimulus & Turbo ready')
