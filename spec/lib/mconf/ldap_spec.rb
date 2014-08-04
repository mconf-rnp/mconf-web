# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe Devise::Strategies::LdapAuthenticatable do
  let(:target) { Mconf::LDAP.new(nil) }

  describe "#initialize" do
    context "receives and stores a `session` object" do
      let(:expected) { "anything" }
      subject { Mconf::LDAP.new(expected) }
      it { subject.instance_variable_get("@session").should eq(expected) }
    end
  end

  describe "#validate_user" do
    it "returns :username if the username is nil"
    it "returns :username if the username is ''"
    it "returns :email if the email is nil"
    it "returns :email if the email is ''"
    it "returns :name if the name is nil"
    it "returns :name if the name is ''"
    it "returns nil if all attributes are ok"
  end

  describe "#find_or_create_user" do
    context "if the username field set in the configurations exists in the user information" do
      it "uses it"
    end
    context "if the username field set in the configurations does not exist in the user information" do
      it "uses a default username"
    end
    context "if the name field set in the configurations exists in the user information" do
      it "uses it"
    end
    context "if the name field set in the configurations does not exist in the user information" do
      it "uses a default name"
    end
    context "if the email field set in the configurations exists in the user information" do
      it "uses it"
    end
    context "if the email field set in the configurations does not exist in the user information" do
      it "uses a default email"
    end
    it "calls #find_or_create_token with the correct parameters to get the token"
    it "calls #create_account with the correct parameters to get the user"
    it "sets the user in the token and saves it"
    it "returns the user created"
    it "returns nil if the creation of the token failed"
    it "returns nil if the creation of the user failed"
  end

  describe "#sign_user_in" do
    it "stores information about the user in the session"
  end

  describe "#signed_in?" do
    context "if the session is not defined" do
      let(:ldap) { Mconf::LDAP.new(nil) }
      subject { ldap.signed_in? }
      it { should be_false }
    end

    context "if the session has no :ldap_data key" do
      let(:ldap) { Mconf::LDAP.new({}) }
      subject { ldap.signed_in? }
      it { should be_false }
    end

    context "if the session has :ldap_data key" do
      let(:ldap) { Mconf::LDAP.new({ :ldap_data => {} }) }
      subject { ldap.signed_in? }
      it { should be_true }
    end
  end

  describe "#find_or_create_token" do
    it "returns the token found if one already exists"
    it "creates a new token for the identifier passed if it doesn't exist yet"

    # These tests are here to prevent errors when creating the token, because the id passed is
    # usually not a standard ruby string, but a Net::BER::BerIdentifiedString created by net-ldap.
    # More at: https://github.com/hallelujah/valid_email/issues/22
    it "converts the id passed to a string"
  end

  describe "#create_account" do
    it "returns the user found if one already exists"
    context "if the target user doesn't exist yet, creates a new user" do
      it "with a random password"
      it "with the email, username and full_name passed"
      it "skips the confirmation, marking the user as already confirmed"
    end

    # These tests are here to prevent errors when creating the token, because the id passed is
    # usually not a standard ruby string, but a Net::BER::BerIdentifiedString created by net-ldap.
    # More at: https://github.com/hallelujah/valid_email/issues/22
    it "converts the id passed to a string"
    it "converts the username passed to a string"
    it "converts the full_name passed to a string"
  end

  describe "#get_principal_name" do
    context "returns nil if there's no shib data in the session" do
      let(:ldap) { Mconf::LDAP.new({}) }
      subject { ldap.get_principal_name }
      it { should be_nil }
    end

    context "when there's ldap data in the session" do
      let(:ldap) { Mconf::LDAP.new(session) }

      context "returns the name pointed by the site's 'ldap_principal_name_field'" do
        let(:session) { { :ldap_data => { 'principal_name' => 'my-name' } } }
        subject { ldap.get_principal_name }
        before {
          Site.current.update_attributes(:ldap_principal_name_field => 'principal_name')
        }
        it { should eq('my-name') }
      end

      context "if 'ldap_principal_name_field' is not set, returns nil" do
        let(:session) { { :ldap_data => { } } }
        subject { ldap.get_principal_name }
        before {
          Site.current.update_attributes(:shib_principal_name_field => nil)
        }
        it { should be_nil }
      end

      context "returns nil if the name is not set" do
        let(:session) { { :ldap_data => { } } }
        subject { ldap.get_principal_name }
        before {
          Site.current.update_attributes(:shib_principal_name_field => 'name')
        }
        it { should be_nil }
      end

      # see issue #973
      context "clones the result string to prevent it from being modified" do
        let(:original) { 'my-name' }
        let(:session) { { :ldap_data => { 'principal_name' => original } } }
        before {
          Site.current.update_attributes(:ldap_principal_name_field => 'principal_name')
          @subject = ldap.get_principal_name

          # something that would alter the string pointed by it
          @subject.gsub!(/my-name/, 'altered-name')
        }
        it { @subject.should eq('altered-name') }
        it { original.should eq('my-name') }
      end
    end
  end

  describe "#get_institution_identifier" do
    context "returns nil if there's no ldap data in the session" do
      let(:ldap) { Mconf::LDAP.new({}) }
      subject { ldap.get_institution_identifier }
      it { should be_nil }
    end

    context "when there's ldap data in the session" do
      let(:ldap) { Mconf::LDAP.new(session) }

      context "returns the identifier pointed by the site's 'ldap_principal_name_field'" do
        let(:session) { { :ldap_data => { 'principal_name' => 'my-name@mconf.org' } } }
        subject { ldap.get_institution_identifier }
        before {
          Site.current.update_attributes(:ldap_principal_name_field => 'principal_name')
        }
        it { should eq('mconf.org') }
      end

      context "if 'ldap_principal_name_field' is not set, returns nil" do
        let(:session) { { :ldap_data => { } } }
        subject { ldap.get_institution_identifier }
        before {
          Site.current.update_attributes(:ldap_principal_name_field => nil)
        }
        it { should be_nil }
      end

      context "returns nil if the name is not set" do
        let(:session) { { :ldap_data => { } } }
        subject { ldap.get_institution_identifier }
        before {
          Site.current.update_attributes(:ldap_principal_name_field => 'name')
        }
        it { should be_nil }
      end
    end
  end

end
