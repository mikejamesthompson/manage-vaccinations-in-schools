# frozen_string_literal: true

module AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    def authenticate_user!
      if !user_signed_in?
        if request.path != start_path
          store_location_for(:user, request.fullpath)
        end
        flash[:info] = "You must be logged in to access this page."
        redirect_to start_path
      elsif cis2_session? && !selected_cis2_org_is_registered?
        redirect_to users_team_not_found_path
      end
    end

    def cis2_session?
      session.key?(:cis2_info)
    end

    def selected_cis2_org_is_registered?
      Team.exists?(ods_code: session["cis2_info"]["selected_org"]["code"])
    end

    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? &&
        !request.xhr? && !turbo_frame_request?
    end

    def store_user_location!
      return unless user_signed_in?
      return unless storable_location?

      store_location_for(:user, request.fullpath)
    end

    def authenticate_basic
      if Flipper.enabled? :basic_auth
        authenticated =
          authenticate_with_http_basic do |username, password|
            username == Settings.support_username &&
              password == Settings.support_password
          end

        unless authenticated
          request_http_basic_authentication "Application", <<~MESSAGE
        Access is currently restricted to authorised users only.
      MESSAGE
        end
      end
    end

    def after_sign_in_path_for(scope)
      stored_location_for(scope) || dashboard_path
    end
  end
end