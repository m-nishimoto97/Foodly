class ScansController < ApplicationController
  def show
  end

  def new
    @scan = Scan.new
  end

  def create
    @scan = current_user.scans.new(scan_params)

    if @scan.save
      redirect_to scan_path, notice: "Photo uploaded successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def scan_params
    params.require(:scan).permit(:photo)
  end
end
