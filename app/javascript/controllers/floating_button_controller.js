import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="floating-button"
export default class extends Controller {
  static targets = ["options", "optionsleft"]
  connect() {
    this.hide();
  }

  toggle(event) {
    this.optionsTarget.classList.toggle("show");
    this.optionsleftTarget.classList.toggle("show");
  }

  hide() {
    this.optionsTarget.classList.remove("show")
    this.optionsleftTarget.classList.remove("show")
  }

  outside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
