# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :private_set_debug_level

  # This line "injects" the methods into every controller in your app
  include Authentication
  include DbAuditContext

  helper_method :show_header?, :show_footer?, :body_css_classes
  helper_method :current_user, :signed_in?, :admin?
  helper_method :current_ui_settings

  # Runs before every request
  before_action :set_locale
  before_action :set_db_audit_context
  before_action :set_default_meta_tags

  helper_method :admin_context?

  allow_browser versions: :modern

  # This runs after your action but before the HTML is sent to the user
  after_action :cleanup_flashes

  def after_sign_in_path_for(resource)
    admin_root_path
  end


  def show
    set_default_meta_tags
  end

  # ActionController::Parameters Rails builds for every single request before it even reaches Controller.
  def admin_context?
    params[:controller].start_with?("admin/")
  end

  def current_ui_settings
    Current.user&.ui_settings || {}
  end

  def show_header?
    !@hide_top_banner
  end

  def show_footer?
    !@hide_footer
  end

  def body_css_classes
    [
      controller_path.tr("/", "-"),
      action_name,
      ("auth" if defined?(current_user).present? && current_user.nil?)
    ].compact.join(" ")
  end

  def current_user
    # from /models/current.rb
    # Current.user
    @current_user ||= (Current.user || User.find(doorkeeper_token.resource_owner_id)) if doorkeeper_token
  end

  def signed_in?
    Current.user.present?
  end

  def admin?
    Current.user&.admin?
  end

  def set_db_audit_context
    # You can safely no-op if you don't have Current.session in some flows
    user_id = Current.user&.id
    session_id = Current.session&.id

    # For API (doorkeeper)
    oauth_app_id = respond_to?(:doorkeeper_token) ? doorkeeper_token&.application_id : nil

    ActiveRecord::Base.connection.execute("select set_config('app.user_id', #{ActiveRecord::Base.connection.quote(user_id.to_s)}, true)")
    ActiveRecord::Base.connection.execute("select set_config('app.session_id', #{ActiveRecord::Base.connection.quote(session_id.to_s)}, true)")
    ActiveRecord::Base.connection.execute("select set_config('app.oauth_application_id', #{ActiveRecord::Base.connection.quote(oauth_app_id.to_s)}, true)")
    ActiveRecord::Base.connection.execute("select set_config('app.request_id', #{ActiveRecord::Base.connection.quote(request.request_id.to_s)}, true)")
    ActiveRecord::Base.connection.execute("select set_config('app.ip', #{ActiveRecord::Base.connection.quote(request.remote_ip.to_s)}, true)")
    ActiveRecord::Base.connection.execute("select set_config('app.user_agent', #{ActiveRecord::Base.connection.quote(request.user_agent.to_s)}, true)")
  end


  # Global notification helper
  # flash[:notice] == notify("", :notice)
  # flash.now[:error] == notify_now("", :error)
  # flash.now[:alert] == notify_now("", :alert)
  def notify(message, type = :success, options = {})
    # 1. Global Kill-Switch
    return unless GlobalConfig.enabled?("allow_flash_notifications")

    # 2. Use the Rails 8 Current object
    # This is much cleaner than searching for "ghost" helpers
    user = options[:user] || Current.user

    # 3. Apply individual preference
    if user.present?
      return unless user.notification_enabled?(type)
    end

    flash[type.to_sym] = message

    # Map symbols to your CSS classes
    # key = case type
    #       when :success, :notice then :success
    #       when :alert, :error   then :alert
    #       when :info            then :info
    #       when :warning         then :warning
    #       else type
    #       end
    #
    # flash[key] = message
  end

  def notify_now(message, type = :success)
    render turbo_stream: turbo_stream.append("flash-registry",
                                             partial: "shared/flash/toast",
                                             locals: { message: message, type: type })
  end


  def current_ui_settings
    # Default settings if the field is empty
    {
      layout: "right",
      explorer_width: 300,
      theme: "dark"
    }.merge(current_user&.settings || {}).symbolize_keys
  end
  helper_method :current_ui_settings



  private
  # before_action methods; security enforcement methods; internal helpers

  def hide_header! = @hide_top_banner = true
  def hide_footer! = @hide_footer = true

  def set_locale
    # 1. Try URL param, 2. Try session, 3. Default to English
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale

    # Keep the session in sync with the URL
    session[:locale] = I18n.locale
  end

  # This ensures that signup_path, login_path, etc.,
  # automatically include the current locale in the URL.
  def default_url_options
    { locale: I18n.locale }
  end

  def require_admin!
    return if Current.user&.has_role?(:admin)
    redirect_to root_path, alert: "Not authorized"
  end

  def set_default_meta_tags
    set_meta_tags(
      title: "SITE TITLE",
      description: "site description",
      keywords: "keyword1, keyword2, keyword3"
    )
  end

  # if bots are cached - insert some statistics in the table
  def log_bot_event(note_text)
    # This reads the IP, accepts your note, and saves to your custom schema
    Sc08Analytics::BotAttempt.create!(
      ip: request.remote_ip,
      note: "#{note_text} | UserAgent: #{request.user_agent}",
      user_agent: request.user_agent,
      event_at: Time.current
    )
  rescue => e
    # Ensures your app never crashes if the analytics table has an issue
    Rails.logger.error "📊 Analytics Fail: #{e.message}"
  end


  def cleanup_flashes
    # If Master switch is OFF, wipe everything.
    if !GlobalConfig.enabled?("allow_flash_notifications")
      flash.clear
      return
    end

    # 2. User JSONB Filter
    if current_user
      # We look at what is currently in the "flash bag"
      flash.keys.each do |key|
        unless current_user.notification_enabled?(key)
          flash.discard(key) # This tells Rails: "Don't carry this over to the next page"
          flash.delete(key)  # This tells Rails: "Remove it from the current request too"
        end
      end
    end
  end

  def private_set_debug_level
    # If the logged-in user has "dev_mode" enabled in their JSON settings...
    User.debug_mode = Current.user&.notification_enabled?(:dev_mode)
  end
end
