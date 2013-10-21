# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class ManageController < ApplicationController
  authorize_resource :class => false

  def users
    @users =
      if current_user.superuser?
        User.find_by_id_with_disabled(:all,:order => "username")
      else
        current_user.institution.users.find(:all, :order => "username")
      end

    @users = @users.paginate(:page => params[:page], :per_page => 20)

    render :layout => 'no_sidebar'
  end

  def spaces
    @spaces =
      if current_user.superuser?
        Space.find_with_disabled(:all,:order => "name")
      else
        current_user.institution.spaces.find(:all, :order => "name")
      end
    @spaces = @spaces.paginate(:page => params[:page], :per_page => 20)
  end

  def institutions
    @institutions = Institution.find(:all, :order => "name").paginate(:page => params[:page], :per_page => 20)
  end

  def spam
    @spam_events = Event.where(:spam => true).all
    @spam_posts = Post.where(:spam => true).all
    render :layout => 'no_sidebar'
  end

end
