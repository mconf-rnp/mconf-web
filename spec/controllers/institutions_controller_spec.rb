require 'spec_helper'

# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

describe InstitutionsController do

  render_views

  describe "#show" do
    let(:institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    before(:each) { get :show, :id => institution.to_param }

    context "template and view" do
      it { should render_with_layout("no_sidebar") }
      it { should render_template("institutions/show") }
    end

    it "assigns @institution" do
      should assign_to(:institution).with(instance_of(Institution))
    end
  end

  describe "#new" do
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    context "template and view" do
      before(:each) { get :new }
      it { should render_with_layout("application") }
      it { should render_template("institutions/new") }
    end

    context "template and view via xhr" do
      before(:each) { xhr :get, :new }
      it { should_not render_with_layout() }
      it { should render_template("institutions/new") }
    end

    it "assigns @institution" do
      get :new
      should assign_to(:institution).with(instance_of(Institution))
    end
  end

  describe "#create" do
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    context "with valid attributes" do
      let(:institution) { FactoryGirl.build(:institution) }

      describe "creates the new institution with the correct attributes" do
        before(:each) {
          expect {
            post :create, :institution => {:name => institution.name}
          }.to change(Institution, :count).by(1)
        }
      end

      context "redirects to the management path" do
        before(:each) { post :create, :institution => {:name => institution.name} }
        it { should redirect_to(manage_institutions_path) }
      end

      describe "assigns @institution with the new institution" do
        before(:each) { post :create, :institution => {:name => institution.name} }
        it { should assign_to(:institution).with(Institution.last) }
      end

      describe "sets the flash with a success message" do
        before(:each) { post :create, :institution => {:name => institution.name} }
        it { should set_the_flash.to(I18n.t('institution.created')) }
      end
    end

    context "with invalid attributes" do
      # let(:invalid_attributes) { FactoryGirl.attributes_for(:institution, :name => nil) }

      # it "assigns @institution with the new institution"

      # describe "renders the view institutions/new with the correct layout" do
      #   before(:each) { post :create, :institution => invalid_attributes }
      #   it { should render_with_layout("application") }
      #   it { should render_template("institutions/new") }
      # end

      # it "does not create a new activity for the space that failed to be created"
    end
  end

  describe "#update" do
    it { should_authorize an_instance_of(Institution), :update, via: :post,id: FactoryGirl.create(:institution).to_param, institution: {} }

    let(:institution) { FactoryGirl.create(:institution) }
    let(:attrs) { FactoryGirl.attributes_for(:institution) }
    let(:params) {
      {
        id: institution.to_param,
        controller: "institution",
        action: "update",
        institution: attrs
      }
    }

    let(:allowed_params) {
      [ :acronym, :name, :user_limit, :can_record_limit, :identifier, :force_shib_login,
      :require_space_approval, :forbid_user_space_creation, :recordings_disk_quota ]
    }

    before {
      attrs.stub(:permit).and_return(attrs)
      controller.stub(:params).and_return(params)
    }

    context "when user is a global admin" do
      let(:user) { FactoryGirl.create(:superuser) }

      before(:each) {
        sign_in(user)
        put :update, id: institution.to_param, institution: attrs
      }
      it { attrs.should have_received(:permit).with(*allowed_params) }
      it { should redirect_to(manage_institutions_path) }
    end

    context "when the user is an institution admin" do
      let(:user) { FactoryGirl.create(:user) }

      before(:each) {
        sign_in(user)
        expect {
          put :update, id: institution.to_param, institution: attrs
        }.to raise_error(CanCan::AccessDenied)
      }

      it { institution }
    end

    context "when the user is normal user" do
      let(:user) { FactoryGirl.create(:user) }

      before(:each) {
        sign_in(user)
        expect {
          put :update, id: institution.to_param, institution: attrs
        }.to raise_error(CanCan::AccessDenied)
      }

      it { institution }
    end

  end

  describe "#edit" do
    let(:institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    before(:each) { get :edit, :id => institution.to_param }

    context "template and view" do
      it { should render_template("institutions/edit") }
    end

    it "assigns @institution" do
      should assign_to(:institution).with(institution)
    end
  end

  it "#destroy"
  it "#correct_duplicate"
  it "#users"
  it "#spaces"
  it "#select"

  describe "abilities", :abilities => true do
    set_custom_ability_actions([:users, :spaces])
    render_views(false)

    let(:hash) { { :id => target.to_param } }
    let(:attrs) { FactoryGirl.attributes_for(:institution) }
    let(:hash_with_attrs) { hash.merge!(:institution => attrs) }

    context "for a superuser", :user => "superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      before(:each) { login_as(user) }

      it { should allow_access_to(:new) }
      it { should allow_access_to(:select) }
      it { should allow_access_to(:create).via(:post) }

      context "in an institution" do
        let(:target) { FactoryGirl.create(:institution) }

        it { should allow_access_to(:show, hash) }
        it { should allow_access_to(:edit, hash) }
        it { should allow_access_to(:users, hash) }
        it { should allow_access_to(:update, hash_with_attrs).via(:post) }
        it { should allow_access_to(:destroy, hash_with_attrs).via(:delete) }
      end
    end

    context "for a normal user", :user => "normal" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { login_as(user) }

      it { should_not allow_access_to(:new) }
      it { should_not allow_access_to(:create).via(:post) }

      context "in an institution" do
        let(:target) { FactoryGirl.create(:institution) }

        context "he is not a member of" do
          it { should_not allow_access_to(:show, hash) }
          it { should_not allow_access_to(:edit, hash) }
          it { should_not allow_access_to(:users, hash) }
          it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
        end

        context "he is a member of" do
          context "with the role 'Admin'" do
            before(:each) { target.add_member!(user, "Admin") }

            it { should allow_access_to(:show, hash) }
            it { should_not allow_access_to(:edit, hash) }
            it { should allow_access_to(:users, hash) }
            it { should allow_access_to(:spaces, hash) }
            it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
          end

          context "with the role 'User'" do
            before(:each) { target.add_member!(user, "User") }

            it { should_not allow_access_to(:show, hash) }
            it { should_not allow_access_to(:edit, hash) }
            it { should_not allow_access_to(:users, hash) }
            it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
          end
        end
      end
    end

    context "for an anonymous user", :user => "anonymous" do
      it { should allow_access_to(:select) }
      it { should_not allow_access_to(:new) }
      it { should_not allow_access_to(:create) }

      context "in an institution" do
        let(:target) { FactoryGirl.create(:institution) }
        it { should_not allow_access_to(:show, hash) }
        it { should_not allow_access_to(:edit, hash) }
        it { should_not allow_access_to(:users, hash) }
        it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
      end
    end
  end

end
