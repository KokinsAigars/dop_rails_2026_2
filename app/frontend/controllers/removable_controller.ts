import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        // Auto-remove after 5 seconds
        setTimeout(() => {
            this.remove()
        }, 5000)
    }

    remove() {
        this.element.remove()
    }
}