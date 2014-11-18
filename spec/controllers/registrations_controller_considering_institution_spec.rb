# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe RegistrationsController do
  render_views

  describe "#create" do
    before { @request.env["devise.mapping"] = Devise.mappings[:user] }
    let(:attributes) {
      attrs = FactoryGirl.attributes_for(:user).slice(:username, :_full_name, :email, :password)
      attrs.merge!(institution_id: FactoryGirl.create(:institution).id)
      attrs
    }
    let(:institution) { FactoryGirl.create(:institution) }

    context "allows the user to select an institution" do
      before(:each) {
        attributes.merge!({ institution_id: institution.id })
        expect {
          post :create, :user => attributes
        }.to change{ User.count }.by(1)
      }
      it { should redirect_to(my_home_path) }
      it { User.last.institution.should eql(institution) }
      it { should assign_to(:institution).with(institution) }
    end

    context "if the user doesn't select an institution" do
      context "includes the error on institution_id" do
        before(:each) {
          attributes.merge!({ institution_id: nil })
          expect {
            post :create, :user => attributes
          }.not_to change{ User.count }
        }
        it { should render_template(:new) }
        it { controller.resource.errors.messages.should have_key(:institution_id) }
        it { controller.resource.errors.messages[:institution_id].should include(I18n.t("errors.messages.blank")) }
        it { assigns(:institution).should be_nil }
      end

      context "includes the error on the other attributes too" do
        before(:each) {
          attributes.merge!({ institution_id: nil, email: nil })
          expect {
            post :create, :user => attributes
          }.not_to change{ User.count }
        }
        it { controller.resource.errors.messages.should have_key(:email) }
        it { controller.resource.errors.messages[:email].should include(I18n.t("errors.messages.blank")) }
      end
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
