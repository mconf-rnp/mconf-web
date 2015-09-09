class InstitutionsController < ApplicationController

  load_and_authorize_resource :find_by => :permalink
  skip_load_resource :only => :index

  respond_to :js, :only => [:select]
  respond_to :html, :only => [:index, :new, :edit, :users]

  def new
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  def show
    respond_to do |format|
      format.html { render layout: 'no_sidebar' }
      format.json { render json: @institution.to_json }
    end
  end

  def create
    @institution = Institution.new(institution_params)

    if @institution.save
      flash[:success] = t('institution.created')
      respond_to do |format|
        format.html { redirect_to manage_institutions_path }
      end
    else
      respond_with @institution do |format|
        format.html { render :new }
      end
    end

  end

  def update
    if @institution.update_attributes(institution_params)
      respond_to do |format|
        format.html {
          flash[:success] = t('institution.updated')
          redirect_to manage_institutions_path
        }
      end

    else
      flash[:error] = t('error.change')
      respond_with @institution do |format|
        format.html { render :edit }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  def destroy
    @institution.destroy
    respond_to do |format|
      flash[:notice] = t('institution.deleted')
      format.html { redirect_to request.referer }
      format.js
    end
  end

  def correct_duplicate
  end

  def users
    @users = @institution.users.where(:approved => true)

    @permissions = @users.map do |u|
      u.permissions.where(:subject_type => 'Institution', :subject_id => @institution.id).first
    end

    @permissions.sort! do |x,y|
      x.user.name <=> y.user.name
    end
    @roles = Institution.roles

    render :layout => 'no_sidebar'
  end

  def spaces
    @spaces = @institution.spaces
    render :layout => 'no_sidebar'
  end

  def select
    @institutions = Institution.search(params[:q])

    respond_to do |format|
      format.json {
        render :json => @institutions.map(&:to_json)
      }
    end
  end

  allow_params_for :institution
  def allowed_params
    [ :acronym, :name, :user_limit, :can_record_limit, :identifier, :force_shib_login,
      :require_space_approval, :forbid_user_space_creation, :recordings_disk_quota ]
  end

end
