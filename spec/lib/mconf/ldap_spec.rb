# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe Mconf::LDAP do
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
    it "returns nil even if the principal name is not set"
  end

  describe "#find_or_create_user" do
    let(:ldap_user) { FactoryGirl.build(:ldap_user) }
    let(:ldap_configs) { FactoryGirl.create(:site) }

    context "if the username field set in the configurations exists in the user information" do
      before {
        ldap_configs.ldap_username_field = 'custom-uid'
      }

      context "uses it" do
        before {
          ldap_user['custom-uid'] = 'my-username'
          expect {
            expect {
              target.find_or_create_user(ldap_user, ldap_configs)
            }.to change{ LdapToken::count }.by(1)
          }.to change{ User::count }.by(1)
        }
        it { User.last.username.should eql('my-username') }
      end

      context "if the content is an email, uses only the first part as the username" do
        before {
          ldap_user['custom-uid'] = 'my-username@my-domain.com'
          target.find_or_create_user(ldap_user, ldap_configs)
        }
        it { User.last.username.should eql('my-username') }
      end
    end

    context "if the username field set in the configurations does not exist in the user information"do
      before {
        ldap_configs.ldap_username_field = 'custom-uid'
      }

      context "uses the default field 'uid'" do
        before {
          ldap_user['uid'] = 'my-username'
          ldap_user['custom-uid'] = nil
          target.find_or_create_user(ldap_user, ldap_configs)
        }
        it { User.last.username.should eql('my-username') }
      end
    end

    context "if the name field set in the configurations exists in the user information" do
      before {
        ldap_configs.ldap_name_field = 'custom-cn'
      }

      context "uses it" do
        before {
          ldap_user['custom-cn'] = 'my-name'
          expect {
            expect {
              target.find_or_create_user(ldap_user, ldap_configs)
            }.to change{ LdapToken::count }.by(1)
          }.to change{ User::count }.by(1)
        }
        it { User.last.name.should eql('my-name') }
      end
    end

    context "if the name field set in the configurations does not exist in the user information"do
      before {
        ldap_configs.ldap_name_field = 'custom-cn'
      }

      context "uses the default field 'cn'" do
        before {
          ldap_user['cn'] = 'my-name'
          ldap_user['custom-cn'] = nil
          target.find_or_create_user(ldap_user, ldap_configs)
        }
        it { User.last.name.should eql('my-name') }
      end
    end

    context "if the email field set in the configurations exists in the user information" do
      before {
        ldap_configs.ldap_email_field = 'custom-mail'
      }

      context "uses it" do
        before {
          ldap_user['custom-mail'] = 'my-email@my-domain.com'
          expect {
            expect {
              target.find_or_create_user(ldap_user, ldap_configs)
            }.to change{ LdapToken::count }.by(1)
          }.to change{ User::count }.by(1)
        }
        it { User.last.email.should eql('my-email@my-domain.com') }
      end
    end

    context "if the email field set in the configurations does not exist in the user information"do
      before {
        ldap_configs.ldap_email_field = 'custom-mail'
      }

      context "uses the default field 'mail'" do
        before {
          ldap_user['mail'] = 'my-email@my-domain.com'
          ldap_user['custom-mail'] = nil
          target.find_or_create_user(ldap_user, ldap_configs)
        }
        it { User.last.email.should eql('my-email@my-domain.com') }
      end
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
      it { should be_falsey }
    end

    context "if the session has no :ldap_data key" do
      let(:ldap) { Mconf::LDAP.new({}) }
      subject { ldap.signed_in? }
      it { should be_falsey }
    end

    context "if the session has :ldap_data key" do
      let(:ldap) { Mconf::LDAP.new({ :ldap_data => {} }) }
      subject { ldap.signed_in? }
      it { should be_truthy }
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

  describe "#find_account" do
    let(:ldap) { Mconf::LDAP.new({}) }
    let(:user) { FactoryGirl.create(:user) }

    it ("returns the user found if it exists") {
      ldap.send(:find_account, user.email).should eql(user)
    }

    it ("matches the user using a case-insensitive search") {
      ldap.send(:find_account, user.email.upcase).should eql(user)
    }

    it ("returns nil if the user is not found") {
      ldap.send(:find_account, user.email + "-invalid").should be_nil
    }
  end

  describe "#create_account" do
    let(:ldap) { Mconf::LDAP.new({}) }
    let(:user) { FactoryGirl.create(:user) }
    let(:token) { LdapToken.create!(identifier: user.email) }

    context "creates a new user" do
      let(:token) { LdapToken.create!(identifier: 'any@ema.il') }
      before(:each) {
        expect {
          @subject = ldap.send(:create_account, 'any@ema.il', 'any-username', 'John Doe', token).reload
        }.to change { User.count }.by(1)
      }

      context "with a random password" do
        it { @subject.password.should_not be_nil }
        it { @subject.password.should_not eql('') }
      end

      context "with email set" do
        it { @subject.email.should_not be_nil }
        it ("and correct") { @subject.email.should eql('any@ema.il') }
      end

      context "with username set" do
        it { @subject.username.should_not be_nil }
        it ("and correct") { @subject.username.should eql('any-username') }
      end

      context "with name set" do
        it { @subject.name.should_not be_nil }
        it ("and correct") { @subject.name.should eql('John Doe') }
      end

      context "skips the confirmation, marking the user as already confirmed" do
        it { @subject.confirmed_at.should_not be_nil }
        it { @subject.confirmed_at.should be_between(Time.now - 2.seconds, Time.now) }
      end

      context "creates a RecentActivity" do
        subject { RecentActivity.where(key: 'ldap.user.created').last }
        it ("should exist") { subject.should_not be_nil }
        it ("should point to the right trackable") { subject.trackable.should eq(User.last) }
        it ("should be owned by an LdapToken") { subject.owner.class.should be(LdapToken) }
        it ("should be owned by the correct LdapToken") { subject.owner_id.should eql(token.id) }
        it("should be unnotified") { subject.notified.should be(false) }
      end

    end

    shared_examples "fails to create account and RecentActivity" do
      before(:each) {
        expect {
          @subject = ldap.send(:create_account, email, username, name, token)
        }.not_to change { User.count }
      }

      it("user should not be created") { @subject.should be_nil }
      it("should not create an activity") { RecentActivity.where(key: 'ldap.user.created').should be_empty }
    end

    context "with invalid data" do
      let(:token) { LdapToken.create!(identifier: 'any@ema.il') }
      let(:email) { 'any@ema.il' }
      let(:username) { 'any-username' }
      let(:name) { 'John Doe' }

      context "email not informed" do
        let(:email) { '' }
        include_examples "fails to create account and RecentActivity"
      end

      context "username not informed" do
        let(:username) { '' }
        include_examples "fails to create account and RecentActivity"
      end

      context "name not informed" do
        let(:name) { '' }
        include_examples "fails to create account and RecentActivity"
      end

    end

    # These tests are here to prevent errors when creating the token, because the id passed is
    # usually not a standard ruby string, but a Net::BER::BerIdentifiedString created by net-ldap.
    # More at: https://github.com/hallelujah/valid_email/issues/22
    it "converts the id passed to a string"
    it "converts the username passed to a string"
    it "converts the full_name passed to a string"

  end

  describe "#set_user_institution" do
    let(:ldap) { Mconf::LDAP.new({}) }
    before {
      Site.current.update_attributes(:ldap_principal_name_field => 'principal_name')
    }

    context "if the user has no institution set yet" do
      let(:user) { FactoryGirl.create(:user, :institution => nil) }

      context "does nothing if the user has no principal name set" do
        let(:ldap_user) { base_ldap_user("principal_name" => nil) }
        before(:each) { @result = ldap.set_user_institution(user, ldap_user, Site.current) }
        it { @result.should be(true) }
        it { user.institution.should be_nil }
      end

      context "does nothing if the user has a principal name without an institution in it" do
        let(:ldap_user) { base_ldap_user("principal_name" => "any-without-institution") }
        before(:each) { @result = ldap.set_user_institution(user, ldap_user, Site.current) }
        it { @result.should be(true) }
        it { user.institution.should be_nil }
      end

      context "does nothing if there's no institution with the identifier found" do
        let(:ldap_user) { base_ldap_user("principal_name" => "user@institution.com") }
        before(:each) { @result = ldap.set_user_institution(user, ldap_user, Site.current) }
        subject { ldap.set_user_institution(user, Site.current, ldap_user) }
        it { @result.should be(true) }
        it { user.institution.should be_nil }
      end

      context "adds the user in the institution if an institution is found" do
        let(:ldap_user) { base_ldap_user("principal_name" => "user@institution.com") }
        let(:institution) { FactoryGirl.create(:institution, identifier: "institution.com") }
        before(:each) {
          institution
          @result = ldap.set_user_institution(user, ldap_user, Site.current)
        }
        it { @result.should be(true) }
        it { user.institution.should eql(institution) }
      end

      context "uses `mail` as the default field to get the principal name" do
        let(:ldap_user) { base_ldap_user("mail" => "user@institution.com") }
        let(:institution) { FactoryGirl.create(:institution, identifier: "institution.com") }
        before(:each) {
          institution
          Site.current.update_attributes(:ldap_principal_name_field => nil)
          @result = ldap.set_user_institution(user, ldap_user, Site.current)
        }
        it { @result.should be(true) }
        it { user.institution.should eql(institution) }
      end

      # all previous tests use string keys
      context "works if the principal name is set with a symbol key" do
        let(:ldap_user) { base_ldap_user(mail: "user@institution.com") }
        let(:institution) { FactoryGirl.create(:institution, identifier: "institution.com") }
        before(:each) {
          institution
          @result = ldap.set_user_institution(user, ldap_user, Site.current)
        }
        it { @result.should be(true) }
        it { user.reload.institution.should eql(institution) }
      end
    end

    context "doesn't change the institution if the user already has an institution set" do
      let(:institution1) { FactoryGirl.create(:institution, identifier: "institution.com") }
      let(:institution2) { FactoryGirl.create(:institution, identifier: "another.com") }
      let(:user) { FactoryGirl.create(:user, institution: institution1) }
      let(:ldap_user) { { principal_name: "user@another.com" } }
      before(:each) {
        institution1
        institution2
        @result = ldap.set_user_institution(user, ldap_user, Site.current)
      }
      it { @result.should be(false) }
      it { user.institution.should eql(institution1) }
    end
  end

  # Creates a real object that's returned by LDAP with the information of the user.
  # A lot better to use the real object here, since it has some particularities not so
  # easy to reproduce with mocks.
  def base_ldap_user(hash)
    r = Net::LDAP::Entry.new
    hash.each do |key, value|
      r[key] = value
    end
    r
  end
end
