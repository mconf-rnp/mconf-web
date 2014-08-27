# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe SessionsController do
  render_views

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#new" do
    context "if there's already a user signed in" do
      before do
        login_as(FactoryGirl.create(:user))
        get :new
      end
      it { response.should redirect_to my_home_path }
    end
  end

  describe "#new" do
    before { @request.env["devise.mapping"] = Devise.mappings[:user] }

    context "if there's already a user signed in" do
      before do
        login_as(FactoryGirl.create(:user))
        get :new
      end
      it { response.should redirect_to my_home_path }
    end
  end

  # The class used to authenticate users via LDAP is a custom strategy for devise, that has its
  # own unit tests. The block here is to test it integrated with devise, calling the action
  # directly on the controller.
  context "authentication via LDAP" do

    # TODO: post user information to /users/login, mock the LDAP connection somehow, and check
    #   the user will actually be authenticated and sign in by devise
    it "authenticates a user via LDAP and logs the user in"
  end

  describe "#create" do

    context "the user's institution forces login via federation" do
      let(:institution) { FactoryGirl.create(:institution, acronym: "UFRGS", force_shib_login: true) }
      let(:user) { FactoryGirl.create(:user, institution: institution) }
      before {
        request.env["HTTP_REFERER"] = "/"
        Site.current.update_attributes(local_auth_enabled: true)
      }
      before(:each) { post :create, params }

      context "when signing in using a username" do
        let(:params) { { user: { login: user.username, password: user.password, remember_me: "0" } } }
        it {
          # check in the body and not in the flash message because somehow the error doesn't
          # appear as a flash message (devise sets it in some other way?)
          response.body.should match(I18n.t('devise.failure.force_shib_login'))
        }
        it { should render_template(:new) }
        it { should_not be_signed_in }
      end

      context "when signing in using an email" do
        let(:params) { { user: { login: user.email, password: user.password, remember_me: "0" } } }
        it {
          # check in the body and not in the flash message because somehow the error doesn't
          # appear as a flash message (devise sets it in some other way?)
          response.body.should match(I18n.t('devise.failure.force_shib_login'))
        }
        it { should render_template(:new) }
        it { should_not be_signed_in }
      end
    end

  end

end
