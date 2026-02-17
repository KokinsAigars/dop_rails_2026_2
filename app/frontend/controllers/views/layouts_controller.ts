
//  *   data-controller="layouts"
//  *   data-layouts-id-value="019a85d5-2002-77a2-bdec-327a1693588a
//

import {Controller} from "@hotwired/stimulus"
import {t} from "@frontend/lib/i18n_js.ts"

export default class extends Controller<HTMLDivElement> {

    // ---- data-target(s) ----
    static targets = [
        "sidebar"
    ]
    declare readonly sidebarTarget: HTMLElement
    // declare readonly sidebarTargets: HTMLElement[]
    declare readonly hasSidebarTarget: boolean

    // ---- Values ----
    static values  = {
        id: String,
    }
    declare readonly idValue: string
    declare readonly hasIdValue: boolean

    // ---- Stimulus Controller Lifecycle ----
    initialize()  {
        //this.ensureInitialize();
        //this.ensureElementHasIdValue();
        // window.addEventListener("i18n:locale-changed", this.onLocaleChanged);
        this.applyInitialSidebar();
    }
    connect() {
        //this.ensureConnect();
        this.render();
    }
    stateValueChanged() {
        this.render();
    }
    disconnect() {
        //this.ensureDisconnect()
        // window.removeEventListener("i18n:locale-changed", this.onLocaleChanged);
    }

    // ---- UPDATE THE VIEW ----
    private render() {
        // console.log("Rendering Layouts Controller...");
    }

    // ---- Public actions (data-action) ----

    private applyInitialSidebar() {
        if (!this.hasSidebarTarget) return

        const saved = localStorage.getItem("sidebar")
        if (saved === "expanded" || saved === "collapsed") {
            this.sidebarTarget.classList.toggle("sidebar--expanded", saved === "expanded")
            this.sidebarTarget.classList.toggle("sidebar--collapsed", saved === "collapsed")
            return
        }

        // No saved preference → fall back to viewport (keeps parity with CSS media query)
        const large = window.matchMedia("(min-width: 1000px)").matches
        this.sidebarTarget.classList.toggle("sidebar--expanded", large)
        this.sidebarTarget.classList.toggle("sidebar--collapsed", !large)
    }

    private setSidebar(state: 'expanded'|'collapsed') {
        localStorage.setItem('sidebar', state)
        document.cookie = `sidebar_state=${state}; path=/; max-age=${60*60*24*365}`
    }

    // data-action="click->layouts#toggleSidebar"
    toggleSidebar() {
        if (!this.hasSidebarTarget) return

        // Toggle classes
        const isExpanded = this.sidebarTarget.classList.toggle("sidebar--expanded")
        if (isExpanded) {
            this.sidebarTarget.classList.remove("sidebar--collapsed")
        } else {
            this.sidebarTarget.classList.add("sidebar--collapsed")
        }
        // Persist preference
        localStorage.setItem("sidebar", isExpanded ? "expanded" : "collapsed")
    }


    // ---- Internal helpers ----
    //initialize
    private ensureInitialize() {
        console.log("🔹 Stimulus Controller \"layouts\" initialized. id: ", this.idValue);
        console.log("data-controller=\"layouts\" has idValue ? : ", this.hasIdValue);
        console.log("Stimulus Controller \"layouts\" element in DOM: ", this.element);
    }
    private ensureElementHasIdValue() {
        // Generate id if missing for controller identity [data-header-id-value]
        if (!this.hasIdValue) {
            const gen = (crypto as any).randomUUID?.() || `tmp-${Date.now()}`
            this.element.setAttribute("data-header-id-value", gen)
            ;(this as any).idValue = gen
        }
    }
    // private onLocaleChanged = (_e: Event) => this.render();

    //connect
    private ensureConnect() {
        console.log("🟢 connect layouts Stimulus Controller");
    }

    //disconnect
    private ensureDisconnect(){
        console.log("🔴 disconnect layouts Stimulus Controller");
    }
}
