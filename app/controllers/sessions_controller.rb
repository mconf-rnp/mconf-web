# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class SessionsController < Devise::SessionsController
  layout 'no_sidebar'

  # To allow other applications to sign in users in Mconf-Web
  skip_before_filter :verify_authenticity_token, :only => [:create]
  prepend_before_filter :check_force_shib_login, :only => [:create]

  private

  def check_force_shib_login
    if (params.has_key?(:user))
      user = User.where(username: params[:user][:login]).first
      if !user.institution.nil? && user.institution.force_shib_login?
        flash[:error] = I18n.t('users.registrations.shibboleth.error.force_shib_login')
        redirect_to root_path
        false
      else
        true
      end
    end
  end

end
