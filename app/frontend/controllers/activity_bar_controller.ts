// app/javascript/controllers/activity_bar_controller.ts
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    switch(event) {
        const target = event.currentTarget.dataset.activityTargetValue // "users" or "apps"

        // 1. Update Icons
        document.querySelectorAll('.activity-icon').forEach(el => el.classList.remove('active'))
        event.currentTarget.classList.add('active')

        // 2. Update Explorer Sections
        document.getElementById('explorer-users').classList.toggle('d-none', target !== 'users')
        document.getElementById('explorer-apps').classList.toggle('d-none', target !== 'apps')
    }
}