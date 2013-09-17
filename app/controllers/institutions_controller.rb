class InstitutionsController < ApplicationController

  load_and_authorize_resource
  skip_load_resource :only => :index

  def index
    @institutions = Institution.find(:all, :order => "name").paginate(:page => params[:page], :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @institution = Institution.new
  end

  def create
    @institution = Institution.new(params[:institution])

    respond_to do |format|
      if @institution.save
        flash[:success] = t('.created')
        format.html { redirect_to request.referer }
      else
        flash[:error] = t('.error.create')
        format.html { redirect_to request.referer }
      end
    end

  end

  def update
    if @institution.update_attributes(params[:institution])
      respond_to do |format|
        format.html {
          flash[:success] = t('.updated')
          redirect_to manage_institutions_path
        }
      end

    else
      flash[:error] = t('.error.update')
      redirect_to institutions_path
    end
  end

  def edit
    respond_to do |format|
      format.html {
        render :partial => "form"
      }
    end
  end

  def destroy
    @institution.destroy
    respond_to do |format|
      flash[:notice] = t('.deleted')
      format.html { redirect_to request.referer }
      format.js
    end
  end
end
