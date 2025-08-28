import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="load-reviews"
export default class extends Controller {
  static values = { url: String };
  static targets = ["offcanvasBody"];
  connect() {
    console.log("connected");

  }

  load (){
    console.log("Loaded");

    console.log(this.urlValue);

    fetch(this.urlValue)
      .then(response => response.text())
      .then(html => {
        this.offcanvasBodyTarget.innerHTML = html
      })
      .catch(err => console.error("Error loading reviews:", err))
    console.log(this.offcanvasBodyTarget);
  }
}
