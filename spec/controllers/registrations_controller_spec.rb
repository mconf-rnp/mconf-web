# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe RegistrationsController do
  render_views

  describe "#new" do
    before { @request.env["devise.mapping"] = Devise.mappings[:user] }

    describe "if registrations are enabled in the site" do
      before(:each) { get :new }
      it { should render_template(:new) }
      it { should render_with_layout("no_sidebar") }
    end

    describe "if registrations are disabled in the site" do
      before { Site.current.update_attribute(:registration_enabled, false) }
      before(:each) { get :new }
      it { should redirect_to(root_path) }
      it { should set_the_flash.to(I18n.t("devise.registrations.not_enabled")) }
    end
  end

  describe "#edit" do
    before { @request.env["devise.mapping"] = Devise.mappings[:user] }
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { login_as(user) }

    describe "if registrations are enabled in the site" do
      before(:each) { get :edit }
      it { should redirect_to(edit_user_path(user)) }
    end

    describe "if registrations are disabled in the site" do
      # the same as when registrations are enabled
      before { Site.current.update_attributes(:registration_enabled => false) }
      before(:each) { get :edit }
      it { should redirect_to(edit_user_path(user)) }
    end
  end

  describe "#create" do
    before { @request.env["devise.mapping"] = Devise.mappings[:user] }
    let(:attributes) {
      FactoryGirl.attributes_for(:user).slice(:username, :_full_name, :email, :password)
    }
    let(:institution) { FactoryGirl.create(:institution) }

    describe "if registrations are enabled in the site" do
      describe "and user select an institution" do
        before(:each) {
          attributes.merge!({ institution_id: institution.id })
          expect {
            post :create, :user => attributes
          }.to change{ User.count }.by(1)
        }
        it { should redirect_to(my_home_path) }
        it { User.last.institution.should eql(institution) }
      end

      describe "and user do not select an institution" do
        before(:each) {
          expect {
            post :create, :user => attributes
          }.not_to change{ User.count }
        }

        it { should redirect_to(register_path) }
        it { expect(session[:user_tmp]).to eql(attributes.except(:password)) }
      end

      describe "and user select an invalid institution" do
        before(:each) {
          attributes.merge!({ institution_id: "invalid_institution_id" })
          expect {
            post :create, :user => attributes
          }.not_to change{ User.count }
        }

        it { should redirect_to(register_path) }
        it { expect(session[:user_tmp]).to eql(attributes.except(:password, :institution_id)) }
      end
    end

    context "if registrations are disabled in the site" do
      before {
        Site.current.update_attributes(registration_enabled: false)
      }
      before(:each) {
        expect {
          post :create, :user => attributes
        }.not_to change{ User.count }
      }
      it { should redirect_to(root_path) }
      it { should set_the_flash.to(I18n.t("devise.registrations.not_enabled")) }
    end

    context "allows the user to select an institution" do
      before(:each) {
        attributes.merge!({ institution_id: institution.id })
        expect {
          post :create, :user => attributes
        }.to change{ User.count }.by(1)
      }
      it { should redirect_to(my_home_path) }
      it { User.last.institution.should eql(institution) }
    end
  end

  context "institution is on CAFe and does not allow local registration" do
    let(:institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:user, :institution => institution) }
    let(:params) { { :user => {:email => user.email, :_full_name=> user.username, :username => user.username,
                 :institution_id => institution.id, :password => user.password, :password_confirmation => user.password} } }
    before {
      controller.stub(:params).and_return(params)
      institution.update_attributes(:force_shib_login => true)
      @request.env["devise.mapping"] = Devise.mappings[:user]
    }
    before(:each) { put :create }
    it { should redirect_to(root_path) }
    it { should set_the_flash.to(I18n.t("users.registrations.shibboleth.error.force_shib_registration"))}
  end

end
