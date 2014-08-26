# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe SessionsController do

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

  context "institution only allow login via federation" do
    let(:institution) { FactoryGirl.create(:institution, :acronym => "UFRGS") }
    let(:user) { FactoryGirl.create(:user, :institution => institution) }
    let(:params) { { :user => {:login => user.username, :password => user.password, :remember_me => "0"} } }
    before {
      institution.update_attributes(:force_shib_login => true)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      controller.stub(:params).and_return(params)
    }
    before(:each){
      login_as(user)
      put :create
    }
    it { should set_the_flash.to(I18n.t('users.registrations.shibboleth.error.force_shib_login')) }
    it { should redirect_to(root_path)}
  end

end
