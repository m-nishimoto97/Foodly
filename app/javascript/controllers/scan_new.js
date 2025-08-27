window.previewImage = function(event) {
  const input = event.target;
  const preview = document.getElementById("preview-image");
  const takePhotoText = document.getElementById("take-photo-text");
  const checkPhotoText = document.getElementById("check-photo-text");
  const submitButton= document.getElementById("photo-submit-button");



  if (input.files[0]) {
    const reader = new FileReader();

    reader.onload = function(e) {
      preview.src = e.target.result
      preview.style.display = "block";
      takePhotoText.style.display = "none";
      checkPhotoText.style.display = "block";
      submitButton.style.display = "block";
    }
    reader.readAsDataURL(input.files[0]);
  }
}
