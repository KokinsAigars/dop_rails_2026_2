

// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form"]

    submit() {
        clearTimeout(this.timeout)
        this.timeout = setTimeout(() => {
            this.element.requestSubmit()
        }, 300) // Wait 300ms after last keystroke
    }
}


// # mise use -g ruby@3.4.7
// # bin/rails generate migration AddTrgmIndexToVocab
// # bin/rails db:migrate