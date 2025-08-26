function previewImage(event) {
  const input = event.target;
  const preview = document.getElementById("preview-image")

  if (input.files[0]) {
    const reader = new FileReader();

    reader.onload = function(e) {
      preview.src = e.target.result
      preview.style.display = "block";
    }
    reader.readAsDataURL(input.files[0]);
  }
}

window.previewImage = previewImage;
