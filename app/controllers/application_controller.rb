class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    dashboard_path  # Ajusta esto al helper de tu ruta
  end
end
