import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["photoButton", "previewImage", "takePhotoText", "checkPhotoText", "photoSubmitButton"]
  connect() {
    console.log("It connected!")
  }

  previewPhoto(event) {
    const input = event.currentTarget

    if (input.files && input.files[0]) {
      const reader = new FileReader()

      reader.onload = (e) => {
        this.previewImageTarget.src = e.target.result
        this.previewImageTarget.style.display = "block"

        this.photoButtonTarget.style.display = "none"
        this.takePhotoTextTarget.style.display = "none"
        this.checkPhotoTextTarget.style.display = "block"
        this.photoSubmitButtonTarget.style.display = "block"
      }

      reader.readAsDataURL(input.files[0])
    }
    console.log("you changed me!")
  }
}
