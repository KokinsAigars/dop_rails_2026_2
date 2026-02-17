
//  id: d
//
//  *   data-controller="activity-icon"
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
    static targets = ["svg", "dot"]
    static classes = ["hover", "active"]
    static values = {
        hasNotification: Boolean,
        originalPath: String,
        activePath: String
    }

    declare readonly svgTarget: SVGElement
    declare readonly hasDotTarget: boolean
    declare readonly dotTarget: HTMLElement
    declare readonly hasNotificationValue: boolean

    connect() {
        // Sync initial notification state
        if (this.hasNotificationValue) this.showNotification()
    }

    // --- Actions ---

    fn_onMouseEnter() {
        this.element.classList.add("is-hovered")
    }

    fn_onMouseLeave() {
        this.element.classList.remove("is-hovered")
    }

    showNotification() {
        if (this.hasDotTarget) this.dotTarget.classList.remove("is-hidden")
    }

    hideNotification() {
        if (this.hasDotTarget) this.dotTarget.classList.add("is-hidden")
    }

    toggleAlert(isAlert: boolean) {
        this.element.classList.toggle("has-alert", isAlert)
    }
}

//
// <!--Icon Controller: this.dispatch("clicked", { detail: { id: 77 } })-->
//
// <!--Workspace Controller: Listens for ui-icon:clicked in the HTML.-->
//
// <!--data-user-workspace-message-count-value="5", your Icon controller can observe that change using a ValueChanged callback and swap the SVG automatically.-->
// <!--fn_handleActivityClick(event) {-->
// <!--this.fn_loadSection(event)     // Load the data-->
// <!--this.addHistoryTab(event)      // Add the tab-->
// <!--// Signal the icon to change (using an event or outlet)-->
// <!--this.dispatch("activity-loaded")-->
// <!--}-->
