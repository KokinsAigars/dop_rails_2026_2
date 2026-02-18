

// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form"]

    connect() {
        // This runs as soon as the form appears on the screen
        console.log("Search controller connected!")
    }

    submit() {
        // Clear the previous timer if the user types again quickly
        clearTimeout(this.timeout)

        // Wait 200-300ms before actually submitting
        this.timeout = setTimeout(() => {
            this.element.requestSubmit()
        }, 300)
    }
}


// # mise use -g ruby@3.4.7
// # bin/rails generate migration AddTrgmIndexToVocab
// # bin/rails db:migrate