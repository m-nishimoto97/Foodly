import { Controller } from "@hotwired/stimulus"

// data-controller="filter-dashboard"
export default class extends Controller {
  static targets = ["seasonalButton", "seasonalInput"]

  connect() {
    this.sync()
  }

  toggleSeasonal(e) {
    e.preventDefault()
    const on = this.seasonalInputTarget.value === "1"
    this.seasonalInputTarget.value = on ? "" : "1"
    this.sync()
  }

  sync() {
    const on = this.seasonalInputTarget.value === "1"

    // Clean up then apply correct state
    this.seasonalButtonTarget.classList.remove("btn-success", "btn-outline-secondary")
    this.seasonalButtonTarget.classList.add(on ? "btn-success" : "btn-outline-secondary")
    this.seasonalButtonTarget.setAttribute("aria-pressed", on ? "true" : "false")
  }
}
