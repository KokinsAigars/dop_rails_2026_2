

// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["item"]

    declare readonly itemTargets: HTMLElement[] //Returns an array of all matching elements. plural form! [s]
    declare readonly hasItemTarget: boolean

    connect() {

        console.log("-- Search Result controller connected!")

        this.fn_processResults()
    }

    // rukkho

    fn_processResults() {

        console.log("--- Stimulus Lifecycle: processResults triggered ---")

        // Log the raw Targets provided by Stimulus
        console.log("Raw itemTargets:", this.itemTargets)

        // 1. Grab all list items inside this specific <ul>
        const items = [...this.itemTargets]
        console.log(`Array count: ${items.length}`)

        if (items.length === 0) return

        if (items.length > 0) {
            // Log the data from the first item to check the 'Intelligence' leak
            const first = items[0]
            console.log("Sample Data Entry:", {
                term: first.dataset.term,
                score: first.dataset.score,
                index: first.dataset.globalIndex
            })
        }

        // Sort them...
        items.sort((a, b) => {
            const scoreA = parseInt(a.dataset.score || "0")
            const scoreB = parseInt(b.dataset.score || "0")

            // 1. First, compare by search rank (0 is best, 3 is worst)
            if (scoreA !== scoreB) {
                return scoreA - scoreB
            }

            // 2. If the ranks are the same (e.g. both are 'ELSE 3' results),
            // sort them alphabetically
            const termA = a.dataset.term || ""
            const termB = b.dataset.term || ""
            return termA.localeCompare(termB, 'pi')
        })

        // Re-append to DOM
        console.log("Sort complete. Re-appending to DOM...")
        this.element.innerHTML = ""
        let lastScore = 0
        items.forEach(item => {
            const currentScore = parseInt(item.dataset.score || "0")

            // If we just jumped from 'High Relevance' (0,1,2) to 'Fuzzy' (3)
            if (lastScore < 3 && currentScore === 3) {
                const hr = document.createElement('li')
                hr.className = "divider-text text-center text-muted small my-2"
                hr.innerHTML = "<hr> Also matches..."
                this.element.appendChild(hr)
            }

            this.element.appendChild(item)
            lastScore = currentScore
        })


        console.log("--- Handle Homographs (The \"Duplicates\") ---")
        const seenCount: Record<string, number> = {}

        items.forEach((item) => {
            const term = item.dataset.term || ""
            seenCount[term] = (seenCount[term] || 0) + 1

            // if more then one time item.dataset.term is found move inside this block
            if (seenCount[term] > 1) {
                // Option: Mark as a duplicate and hide it to keep suggestions clean
                item.classList.add("is-homograph")
                item.style.display = "none"

                // Find the first occurrence and add a "multiple meanings" indicator
                const original = items.find(i => i.dataset.term === term && i.style.display !== "none")
                if (original && !original.querySelector('.homograph-indicator')) {
                    const badge = document.createElement('span')
                    badge.className = "homograph-indicator badge bg-info ms-2"
                    badge.style.fontSize = "0.6rem"
                    badge.innerText = "++" // Indicates more entries exist
                    original.appendChild(badge)
                }
            }
        })

        console.log("--- Lifecycle End ---")
    }
}


// # mise use -g ruby@3.4.7
// # bin/rails generate migration AddTrgmIndexToVocab
// # bin/rails db:migrate