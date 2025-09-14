import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo-rails'
import 'media-chrome'
import '@fortawesome/fontawesome-free/css/all.css'

const application = Application.start()

// Import automatic Stimulus controller loader
import { autoLoadControllers } from '../lib/stimulus_loader'

// Import global store and audio state management
import { AudioStateManager } from '../lib/audio_state_manager'

// Initialize AudioStateManager singleton
const audioStateManager = AudioStateManager.getInstance()

// Make it available globally for debugging (optional)
if (typeof window !== 'undefined') {
  window.audioStateManager = audioStateManager
}

// Automatically load and register all Stimulus controllers
// This replaces manual import and registration
autoLoadControllers(application)

