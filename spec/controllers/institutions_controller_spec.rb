require 'spec_helper'

# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

describe InstitutionsController do

  render_views

  describe "#index" do
  end

  it "#index.json"
  it "#select.json"

  describe "#show" do
    let(:target) { FactoryGirl.create(:public_space) }
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    it {
      get :show, :id => target.to_param
      should respond_with(:success)
    }

    context "layout and view" do
      before(:each) { get :show, :id => target.to_param }
      it { should render_template("spaces/show") }
      it { should render_with_layout("spaces_show") }
    end

  end

  describe "#show.json" do
    it "responds with the correct json"
  end

  describe "#new" do
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    before(:each) { get :new }

    context "template and view" do
      it { should render_with_layout("application") }
      it { should render_template("spaces/new") }
    end

    it "assigns @space" do
      should assign_to(:space).with(instance_of(Space))
    end

    context "for @spaces_examples" do
      let(:do_action) { get :new }
      it_behaves_like "assigns @spaces_examples"
    end
  end

  describe "#create" do
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    context "with valid attributes" do
      let(:space) { FactoryGirl.build(:space) }

      describe "creates the new space with the correct attributes" do
        before(:each) {
          expect {
            post :create, :space => space.attributes
          }.to change(Space, :count).by(1)
        }

        # TODO: for some reason the matcher is not found, maybe we just need to update rspec and other gems
        pending { Space.last.should have_same_attibutes_as(space) }
      end

      context "redirects to the new space" do
        before(:each) { post :create, :space => space.attributes }
        it { should redirect_to(space_path(Space.last)) }
      end

      describe "assigns @space with the new space" do
        before(:each) { post :create, :space => space.attributes }
        it { should assign_to(:space).with(Space.last) }
      end

      describe "sets the flash with a success message" do
        before(:each) { post :create, :space => space.attributes }
        it { should set_the_flash.to(I18n.t('space.created')) }
      end

      describe "adds the user as an admin in the space" do
        before(:each) { post :create, :space => space.attributes }
        it { Space.last.admins.should include(user) }
      end

      describe "sets the user's institution as the space's institution" do
        before(:each) { post :create, :space => space.attributes }
        it { Space.last.institution.should eq(user.institution) }
        it { user.institution.spaces.should include(Space.last) }
      end

      it "creates a new activity for the space created"
    end

    context "with invalid attributes" do
      let(:invalid_attributes) { FactoryGirl.attributes_for(:space, :name => nil) }

      it "assigns @space with the new space"

      describe "renders the view spaces/new with the correct layout" do
        before(:each) { post :create, :space => invalid_attributes }
        it { should render_with_layout("application") }
        it { should render_template("spaces/new") }
      end

      context do
        let(:do_action) { post :create, :space => invalid_attributes }
        it_behaves_like "assigns @spaces_examples"
      end

      it "does not create a new activity for the space that failed to be created"
    end
  end

  describe "#edit" do
    let(:space) { FactoryGirl.create(:space) }
    let(:user) { FactoryGirl.create(:superuser) }
    before(:each) { sign_in(user) }

    before(:each) { get :edit, :id => space.to_param }

    context "template and view" do
      it { should render_with_layout("spaces_show") }
      it { should render_template("spaces/edit") }
    end

    it "assigns @space" do
      should assign_to(:space).with(space)
    end
  end

  it "#update"
  it "#destroy"
  it "#select"
  it "#correct_duplicate"

  describe "abilities", :abilities => true do
    render_views(false)

    let(:hash) { { :id => target.to_param } }
    let(:attrs) { FactoryGirl.attributes_for(:institution) }
    let(:hash_with_attrs) { hash.merge!(:institution => attrs) }

    context "for a superuser", :user => "superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      before(:each) { login_as(user) }

      it { should allow_access_to(:index) }
      it { should allow_access_to(:new) }
      it { should allow_access_to(:create).via(:post) }

      # the permissions are always the same, doesn't matter the type of room, so
      # we have them all in this common method
      shared_examples_for "a superuser accessing a webconf room in SpacesController" do
        it { should allow_access_to(:show, hash) }
        it { should allow_access_to(:edit, hash) }
        it { should allow_access_to(:user_permissions, hash) }
        it { should allow_access_to(:update, hash_with_attrs).via(:post) }
        it { should allow_access_to(:destroy, hash_with_attrs).via(:delete) }
        it { should allow_access_to(:enable, hash_with_attrs).via(:post) }
        it { should allow_access_to(:leave, hash_with_attrs).via(:post) }
        it { should allow_access_to(:webconference, hash) }
        it { should allow_access_to(:recordings, hash) }
        it { should allow_access_to(:edit_recording, hash_recording) }
      end

      context "in a public space" do
        let(:target) { FactoryGirl.create(:public_space) }
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => target.bigbluebutton_room) }

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing a webconf room in SpacesController"
        end

        context "he is a member of" do
          Space::USER_ROLES.each do |role|
            context "with the role '#{role}'" do
              before(:each) { target.add_member!(user, role) }
              it_should_behave_like "a superuser accessing a webconf room in SpacesController"
            end
          end
        end
      end

      context "in a private space" do
        let(:target) { FactoryGirl.create(:private_space) }
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => target.bigbluebutton_room) }

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing a webconf room in SpacesController"
        end

        context "he is a member of" do
          Space::USER_ROLES.each do |role|
            context "with the role '#{role}'" do
              before(:each) { target.add_member!(user, role) }
              it_should_behave_like "a superuser accessing a webconf room in SpacesController"
            end
          end
        end
      end

    end

    context "for a normal user", :user => "normal" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { login_as(user) }

      it { should allow_access_to(:index) }
      it { should allow_access_to(:new) }
      it { should allow_access_to(:create).via(:post) }

      context "in a public space" do
        let(:target) { FactoryGirl.create(:public_space) }
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => target.bigbluebutton_room) }

        context "he is not a member of" do
          it { should allow_access_to(:show, hash) }
          it { should_not allow_access_to(:edit, hash) }
          it { should_not allow_access_to(:user_permissions, hash) }
          it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
          it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:leave, hash_with_attrs).via(:post) }
          it { should allow_access_to(:webconference, hash) }
          it { should allow_access_to(:recordings, hash) }
        end

        context "he is a member of" do
          context "with the role 'Admin'" do
            before(:each) { target.add_member!(user, "Admin") }
            it { should allow_access_to(:show, hash) }
            it { should allow_access_to(:edit, hash) }
            it { should allow_access_to(:user_permissions, hash) }
            it { should allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should allow_access_to(:destroy, hash_with_attrs).via(:delete) }
            it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
            it { should allow_access_to(:leave, hash_with_attrs).via(:post) }
            it { should allow_access_to(:webconference, hash) }
            it { should allow_access_to(:recordings, hash) }
            it { should allow_access_to(:edit_recording, hash_recording) }
          end

          context "with the role 'User'" do
            before(:each) { target.add_member!(user, "User") }
            it { should allow_access_to(:show, hash) }
            it { should_not allow_access_to(:edit, hash) }
            it { should_not allow_access_to(:user_permissions, hash) }
            it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
            it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
            it { should allow_access_to(:leave, hash_with_attrs).via(:post) }
            it { should allow_access_to(:webconference, hash) }
            it { should allow_access_to(:recordings, hash) }
          end
        end
      end

      context "in a private space" do
        let(:target) { FactoryGirl.create(:private_space) }
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => target.bigbluebutton_room) }

        context "he is not a member of" do
          it { should_not allow_access_to(:show, hash) }
          it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
          it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:leave, hash_with_attrs).via(:post) }
          it { should_not allow_access_to(:webconference, hash) }
          it { should_not allow_access_to(:recordings, hash) }
        end

        context "he is a member of" do
          context "with the role 'Admin'" do
            before(:each) { target.add_member!(user, "Admin") }
            it { should allow_access_to(:show, hash) }
            it { should allow_access_to(:edit, hash) }
            it { should allow_access_to(:user_permissions, hash) }
            it { should allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should allow_access_to(:destroy, hash_with_attrs).via(:delete) }
            it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
            it { should allow_access_to(:leave, hash_with_attrs).via(:post) }
            it { should allow_access_to(:webconference, hash) }
            it { should allow_access_to(:recordings, hash) }
            it { should allow_access_to(:edit_recording, hash_recording) }
          end

          context "with the role 'User'" do
            before(:each) { target.add_member!(user, "User") }
            it { should allow_access_to(:show, hash) }
            it { should_not allow_access_to(:edit, hash) }
            it { should_not allow_access_to(:user_permissions, hash) }
            it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
            it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
            it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
            it { should allow_access_to(:leave, hash_with_attrs).via(:post) }
            it { should allow_access_to(:webconference, hash) }
            it { should allow_access_to(:recordings, hash) }
          end
        end
      end

    end

    context "for an anonymous user", :user => "anonymous" do
      it { should allow_access_to(:index) }
      it { should require_authentication_for(:new) }
      it { should require_authentication_for(:create).via(:post) }

      context "in a public space" do
        let(:target) { FactoryGirl.create(:public_space) }
        it { should allow_access_to(:show, hash) }
        it { should_not allow_access_to(:edit, hash) }
        it { should_not allow_access_to(:user_permissions, hash) }
        it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
        it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:leave, hash_with_attrs).via(:post) }
        it { should allow_access_to(:webconference, hash) }
        it { should allow_access_to(:recordings, hash) }
      end

      context "in a private space" do
        let(:target) { FactoryGirl.create(:private_space) }
        it { should_not allow_access_to(:show, hash) }
        it { should_not allow_access_to(:edit, hash) }
        it { should_not allow_access_to(:user_permissions, hash) }
        it { should_not allow_access_to(:update, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:destroy, hash_with_attrs).via(:delete) }
        it { should_not allow_access_to(:enable, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:leave, hash_with_attrs).via(:post) }
        it { should_not allow_access_to(:webconference, hash) }
        it { should_not allow_access_to(:recordings, hash) }
      end
    end

  end

end