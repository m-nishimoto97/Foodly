import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scheduler"
export default class extends Controller {
  static targets = ["searchinput"]
  static values = { url: String }

  submit() {
    const query = this.searchinputTarget.value
    fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
  }

}
