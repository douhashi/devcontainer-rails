import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo-rails'

const application = Application.start()

// Import all Stimulus controllers manually
import LayoutController from '../controllers/layout_controller'
application.register('layout', LayoutController)

console.log('Vite ⚡️ Rails with Stimulus & Turbo ready')
