class InstitutionsController < ApplicationController

  load_and_authorize_resource :find_by => :permalink
  skip_load_resource :only => :index

  def new
    @institution = Institution.new
  end

  def create
    @institution = Institution.new(params[:institution])

    respond_to do |format|
      if @institution.save
        flash[:success] = t('institution.created')
        format.html { redirect_to manage_institutions_path }
      else
        flash[:error] = t('institution.error.create')
        format.html { redirect_to new_institution_path }
      end
    end

  end

  def update
    if @institution.update_attributes(params[:institution])
      respond_to do |format|
        format.html {
          flash[:success] = t('institution.updated')
          redirect_to manage_institutions_path
        }
      end

    else
      flash[:error] = t('institution.error.update')
      redirect_to manage_institutions_path
    end
  end

  def edit
    respond_to do |format|
      format.html
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

  def user_permissions
    @users = @institution.users.order("name ASC")
    @permissions = @institution.permissions.sort{
      |x,y| x.user.name <=> y.user.name
    }
    @roles = Institution.roles
  end

  def select
    @institutions = Institution.search(params[:q])

    respond_to do |format|
      format.json {
        render :json => @institutions.map(&:to_json)
      }
    end
  end

end
