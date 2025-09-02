import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["photoButton", "previewImage", "takePhotoText", "checkPhotoText", "photoSubmitButton", "redoPhotoButton"]
  connect() {
    console.log("It connected!")
  }

  redoPhoto() {
    const redoInput = this.redoPhotoButtonTarget.previousElementSibling; // the hidden file input
    redoInput.value = null; // reset input so the same file can be reselected
  }

  previewPhoto(event) {
    const input = event.currentTarget

    if (input.files && input.files[0]) {
      const reader = new FileReader()

      reader.onload = (e) => {
        this.previewImageTarget.src = e.target.result
        this.previewImageTarget.style.display = "block"

        this.redoPhotoButtonTarget.style.display = "inline"
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
