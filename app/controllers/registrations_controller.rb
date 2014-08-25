# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class RegistrationsController < Devise::RegistrationsController
  layout 'no_sidebar'

  before_filter :check_registration_enabled, :only => [:new, :create]
  prepend_before_filter :check_shib_login_only, :only => [:create]

  def new
  end

  def edit
    redirect_to edit_user_path(current_user)
  end

  private

  def check_registration_enabled
    unless current_site.registration_enabled?
      flash[:error] = I18n.t("devise.registrations.not_enabled")
      redirect_to root_path
      false
    end
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

end
