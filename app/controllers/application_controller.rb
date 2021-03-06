class ApplicationController < ActionController::Base
  include SessionsHelper
  include PermissionFilter
  include Redirect
  include CardsHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  # add different types of flash messages
  add_flash_types :error, :success, :notice, :infos

  http_basic_authenticate_with name: "js-tech", password: Rails.application.secrets.basic_pswd if Rails.env.staging?

  before_action :set_locale

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    respond_to do |format|
      format.html { render 'application/rescue/invalid_authenticity_token.html', layout: 'application' }
      format.js { render 'application/rescue/invalid_authenticity_token.js' }
    end
  end

  def default_url_options(options={})
    locale = I18n.locale
    { locale: (locale == :fr ? nil : locale) }
  end

  def track_activity(trackable, action = params[:action], controller = params[:controller])
    if !trackable.nil? && !trackable.changed?
  	 Activity.create! action: action, controller: controller, trackable: trackable, user: current_user
    end
	end

  def render_message(error)
    render_to_string("application/messages/#{error}", layout: false).html_safe
  end

  def js(enabled, **args)
    @js = enabled
    @js_params = args
  end

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

end
