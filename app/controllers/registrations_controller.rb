# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class RegistrationsController < Devise::RegistrationsController
  layout 'no_sidebar'

  prepend_before_filter :check_shib_login_only, :only => [:create]
  before_filter :check_registration_enabled, :only => [:new, :create]
  before_filter :configure_permitted_parameters, :only => [:create]
  before_filter :check_institution_presence, :only => [:create]

  def new
    if session[:user_tmp]
      @user = User.new session[:user_tmp]
      @user.errors.add(:institution_id, "can't be blank")
      session[:user_tmp] = nil
    end
  end

  def edit
    redirect_to edit_user_path(current_user)
  end

  private

  def check_institution_presence
    if params[:user][:institution_id].blank? or !Institution.where(id: params[:user][:institution_id]).first
      session[:user_tmp] = params[:user].slice(:_full_name, :username, :email).symbolize_keys
      redirect_to register_path
    end
  end

  def check_registration_enabled
    unless current_site.registration_enabled?
      flash[:error] = I18n.t("devise.registrations.not_enabled")
      redirect_to root_path
      false
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).push(*allowed_params)
  end

  def allowed_params
    [:email, :_full_name, :username, :institution_id]
  end

  def check_shib_login_only
    if params.has_key?(:user)
      institution_id = params[:user][:institution_id]
      institution = Institution.where(id: institution_id).first
      if institution && institution.force_shib_login?
        flash[:error] = I18n.t('users.registrations.shibboleth.error.force_shib_registration')
        redirect_to root_path
      end
    end
  end

  private

  # Redirect users to pretty page after registered and not approved
  def after_inactive_sign_up_path_for(resource)
    my_approval_pending_path
  end

end
