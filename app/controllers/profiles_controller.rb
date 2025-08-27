class ProfilesController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(params_user)
      redirect_to profile_path
    else
      render 'show', status: :unprocessable_content
    end
  end

  private

  def params_user
    params.require(:user).permit(:allergy, :username, :preference)
  end
end
