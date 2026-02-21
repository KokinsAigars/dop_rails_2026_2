
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["btn", "pane"]
    static values = {
        activeClass: String,
        defaultTab: String
    }

    connect() {
        // 1. Create a bound function so 'this' always refers to the controller
        this.hashHandler = () => {
            const hash = window.location.hash.replace("#", "")
            if (hash) this.activate(hash)
        }

        // 2. Listen for back/forward browser navigation
        window.addEventListener("hashchange", this.hashHandler)

        // 3. Run the initial check for deep links
        const startTab = window.location.hash.replace("#", "") ||
            this.defaultTabValue ||
            this.btnTargets[0].dataset.tabName
        this.activate(startTab)
    }

    disconnect() {
        // Stop listening to the window when this specific tab-set leaves the DOM
        window.removeEventListener("hashchange", this.hashHandler)
    }

    switch(event) {
        event.preventDefault()
        const tabName = event.currentTarget.dataset.tabName
        window.location.hash = tabName // This triggers the 'hashchange' listener automatically
    }

    activate(tabName) {
        const pane = this.paneTargets.find(p => p.dataset.tabName === tabName)
        if (!pane) return

        this.paneTargets.forEach(p => p.classList.toggle("d-none", p.dataset.tabName !== tabName))
        this.btnTargets.forEach(b => b.classList.toggle(this.activeClassValue, b.dataset.tabName === tabName))
    }

    // copy current URL to clipboard
    copyLink(event) {
        event.preventDefault()

        // 1. Capture the button immediately!
        // This ensures we have a reference to the element inside the promise.
        const button = event.currentTarget
        const url = window.location.href

        navigator.clipboard.writeText(url).then(() => {
            // 2. Visual Feedback using our captured variable
            const originalText = button.innerHTML
            button.innerHTML = "✓ Link Copied!"

            // Optional: Add a CSS class for a "success" look
            button.classList.add("text-success")

            setTimeout(() => {
                button.innerHTML = originalText
                button.classList.remove("text-success")
            }, 2000)

        }).catch(err => {
            console.error("Could not copy text: ", err)
        })
    }


}

