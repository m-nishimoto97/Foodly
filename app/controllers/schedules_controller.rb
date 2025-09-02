class SchedulesController < ApplicationController
  def show
    @schedule = current_user.schedules.new
    @schedules = current_user.schedules.includes(:recipe)
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today

    @recipes = if params[:query].present?
                current_user.recipes.where("name ILIKE ?", "%#{params[:query]}%")
              else
                current_user.recipes
              end
   respond_to do |format|
      format.html
      format.turbo_stream
    end
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
