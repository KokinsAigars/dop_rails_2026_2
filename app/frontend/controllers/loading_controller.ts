import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["spinner"];

    declare readonly spinnerTarget: HTMLElement;

    connect() {
        this.hide();
    }

    show() {
        this.spinnerTarget.classList.remove("hidden");
    }

    hide() {
        this.spinnerTarget.classList.add("hidden");
    }
}
