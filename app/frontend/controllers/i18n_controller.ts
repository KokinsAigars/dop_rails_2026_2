
//  id : 019a4439-a181-7f2e-9b14-ee6bf5787b3c
//
//  *   data-controller="i18n"
//

import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller<HTMLSelectElement> {

    static values = {
        id: String,
        locales: Array as unknown as typeof Array // or just: locales: Array
    };

    declare readonly idValue: string
    declare readonly hasIdValue: boolean
    declare readonly localesValue: string[]

    initialize() {

        // this.ensureInitialize();
        this.ensureElementHasIdValue();
    }

    connect() {

        // Provide a default set if not passed via data-i18n-locales-value
        if (!this.localesValue) (this as any).localesValue = ["en", "lv", "ru"]

        const current = (window.location.pathname.split("/").filter(Boolean)[0]) || "en"
        const select = this.element as HTMLSelectElement
        if ([...select.options].some(o => o.value === current)) {
            select.value = current
        }

    }

    fn_changeLocale() {
        const select = this.element as HTMLSelectElement
        const lang = select.value
        const newUrl = this.fn_swapLocaleInUrl(window.location.href, lang, this.localesValue)

        if (newUrl === window.location.href) {
            // Either force replace, or hard reload
            Turbo.visit(newUrl, { action: "replace" })
            // or: window.location.assign(newUrl)
        } else {
            Turbo.visit(newUrl)
        }
    }


    // ---- Internal helpers ----
    //initialize
    private ensureInitialize() {
        console.log("🔹 Stimulus Controller \"i18n\" initialized. id: ", this.idValue);
        console.log("data-controller=\"i18n\" has idValue ? : ", this.hasIdValue);
        console.log("Stimulus Controller \"i18n\" element in DOM: ", this.element);
    }
    private ensureElementHasIdValue() {
        // Generate id if missing for controller identity [data-signin-id-value]
        if (!this.hasIdValue) {
            const gen = (crypto as any).randomUUID?.() || `tmp-${Date.now()}`
            this.element.setAttribute("data-signin-id-value", gen)
            ;(this as any).idValue = gen
        }
    }

    private fn_swapLocaleInUrl(url: string, lang: string, locales: string[]) {
        const u = new URL(url)

        const parts = u.pathname.split("/").filter(Boolean)
        if (parts.length && locales.includes(parts[0])) {
            parts[0] = lang
        } else {
            parts.unshift(lang)
        }

        u.pathname = "/" + parts.join("/")
        if (u.searchParams.has("locale")) {
            u.searchParams.delete("locale")     // preferred: rely on path segment
            // or: u.searchParams.set("locale", lang)
        }

        return u.toString()
    }

}
