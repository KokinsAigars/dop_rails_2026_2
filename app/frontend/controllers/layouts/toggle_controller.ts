// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "icon"]
    static values = { open: Boolean }

    connect() {
        // Start closed unless specified otherwise
        if (!this.openValue) {
            this.contentTarget.classList.add("d-none")
        }
        console.log('actually connected')
    }

    toggle() {
        this.openValue = !this.openValue
        this.contentTarget.classList.toggle("d-none")

        // Optional: Rotate an arrow icon
        if (this.hasIconTarget) {
            this.iconTarget.classList.toggle("rotate-180")
        }
    }
}

