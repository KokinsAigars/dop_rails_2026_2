
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["item"]

    fn_close(event: Event) {
        event.preventDefault()

        // Add the closing animation class
        this.element.classList.add("flash-closing")

        // Remove from DOM after the animation finishes
        this.element.addEventListener("animationend", () => {
            this.element.remove()
        }, { once: true })
    }
}

