import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="floating-button"
export default class extends Controller {
  static targets = ["options", "optionsleft"]

  toggle() {
    this.optionsTarget.classList.toggle("show");
    this.optionsleftTarget.classList.toggle("show");
  }
}
