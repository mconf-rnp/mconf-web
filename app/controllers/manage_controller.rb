# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class ManageController < ApplicationController
  before_filter :authenticate_user!
  authorize_resource :class => false

  def users
    words = params[:q].try(:split, /\s+/)

    query = if current_user.superuser?
              User.with_disabled.search_by_terms(words, can?(:manage, User))
            else
              # institutional admins search only inside their institution
              # can pass "true" to get private data since it's only for users
              # that belong to the institution
              current_user.institution.users.search_by_terms(words, true)
            end

    query = query.search_order

    # start applying filters
    [:disabled, :approved, :can_record].each do |filter|
      if !params[filter].nil?
        val = (params[filter] == 'true') ? true : [false, nil]
        query = query.where(filter => val)
      end
    end

    auth_methods = []
    auth_methods << :shibboleth if params[:login_method_shib] == 'true'
    auth_methods << :ldap if params[:login_method_ldap] == 'true'
    auth_methods << :local if params[:login_method_local] == 'true'
    query = query.with_auth(auth_methods)

    if params[:admin].present?
      val = (params[:admin] == 'true') ? true : [false, nil]
      query = query.where(superuser: val)
    end

    if params[:institutional_admin].present?
      val = (params[:institutional_admin] == 'true') ? true : [false, nil]
      admin_role = Role.where(name: 'Admin').first
      admins = Permission.where(subject_type: 'Institution', role_id: admin_role.id).pluck(:user_id)
      query = query.where(id: admins)
    end

    # ignore this filter for institution admins
    # here we add the superuser? check to avoid institutional admins to use this filter unless they are also global admin
    if params[:institutions].present? && current_user.superuser?
      permalinks = params[:institutions].split(',')
      ids = Institution.where(permalink: permalinks).ids
      users = Permission.where(subject_type: 'Institution', subject_id: ids).pluck(:user_id)
      query = query.where(id: users)
    end

    @users = query.paginate(page: params[:page], per_page: 20)

    if request.xhr?
      render partial: 'users_list', layout: false
    else
      render layout: 'no_sidebar'
    end
  end

  def spaces
    if current_user.superuser?
      query = Space.with_disabled
    else
      query = current_user.institution.spaces
    end

    words = params[:q].try(:split, /\s+/)
    query = query.search_by_terms(words, can?(:manage, Space)).search_order

    # start applying filters
    [:disabled, :approved].each do |filter|
      if !params[filter].nil?
        val = (params[filter] == 'true') ? true : [false, nil]
        query = query.where(filter => val)
      end
    end

    query = params[:tag] ? query.tagged_with(params[:tag]) : query

    @spaces = query.paginate(:page => params[:page], :per_page => 20)

    if request.xhr?
      render :partial => 'spaces_list', :layout => false, :locals => { :spaces => @spaces }
    else
      render :layout => 'no_sidebar'
    end
  end

  def recordings
    words = params[:q].try(:split, /\s+/)

    query = if current_user.superuser?
              BigbluebuttonRecording.search_by_terms(words)
            else
              # institutional admins search only inside their institution
              # can pass "true" to get private data since it's only for users
              # that belong to the institution
              current_user.institution.recordings.search_by_terms(words)
            end

    query = query.search_order

    [:published, :available].each do |filter|
      if !params[filter].nil?
        val = (params[filter] == 'true') ? true : [false, nil]
        query = query.where(filter => val)
      end
    end

    if params[:playback] == "true"
      query = query.has_playback
    elsif params[:playback] == "false"
      query = query.no_playback
    end

    @recordings = query.paginate(page: params[:page], per_page: 20)

    if request.xhr?
      render partial: 'recordings_list', layout: false, locals: { recordings: @recordings }
    else
      render layout: 'no_sidebar'
    end
  end

  def institutions
    @institutions = Institution.order(:name).paginate(:page => params[:page], :per_page => 20)
    render :layout => 'no_sidebar'
  end

end
