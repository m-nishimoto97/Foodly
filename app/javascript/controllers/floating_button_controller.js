import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="floating-button"
export default class extends Controller {
  static targets = ["options"]

  toggle() {
    console.log("tetetee");

    this.optionsTarget.classList.toggle("show")
  }
}
