import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review-photo"
export default class extends Controller {
  static targets = ["image", "modal"]

  connect() {
    console.log("connected to the controller!")
  }

  open(event) {
    console.log("you clicked me!")
    const imgUrl = event.currentTarget.dataset.modalUrl
    this.imageTarget.src = imgUrl
    this.modalTarget.style.display = "flex"
  }

  close() {
    this.modalTarget.style.display = "none"
    this.imageTarget.src = ""
  }

  closeOnOutsideClick(event) {
    if (event.target === this.modalTarget) this.close()
  }
}
