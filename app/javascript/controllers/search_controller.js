import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["searchinput"]
  submit() {
    this.searchinputTarget.requestSubmit();
  }
}
