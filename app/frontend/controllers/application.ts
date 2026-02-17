import { Application } from "@hotwired/stimulus"
import { startLangObserver } from "@frontend/lib/i18n_js.ts";

const application = Application.start()
application.debug = false
window.Stimulus = application
export { application }

// <html lang=""> attribute is handled by Rails I18n API
// Start i18n <html lang=""> attribute watcher for frontend scripts/controllers
startLangObserver();
