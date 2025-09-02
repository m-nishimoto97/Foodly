class SchedulesController < ApplicationController
  def show
    @schedule = current_user.schedules.new
    @schedules = current_user.schedules.includes(:recipe)
  end

  def create
    @schedule = current_user.schedules.new(schedule_params)
    if @schedule.save
      redirect_to schedule_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(:date, :recipe_id)
  end
end
