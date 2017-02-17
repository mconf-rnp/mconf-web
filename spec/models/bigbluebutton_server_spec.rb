# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe BigbluebuttonServer do

  describe "from initializers/bigbluebutton_rails" do
    context "should have a method .default" do
      it { BigbluebuttonServer.should respond_to(:default) }
      it("returns the first server") {
        BigbluebuttonServer.default.should eq(BigbluebuttonServer.first)
      }
    end
  end

  describe "after update" do
    let!(:default) { BigbluebuttonServer.default }
    let!(:institution_server) { FactoryGirl.create(:bigbluebutton_server, url: default.url + '-other') }

    it "when the default server is updated, updates the other servers" do
      new_url = "http://mconf.org/bigbluebutton/api"
      default.update_attributes(url: new_url)
      institution_server.reload.url.should eql(new_url)
    end

    it "when another server is updated, doesn't update the default server" do
      new_url = "http://mconf.org/bigbluebutton/api"
      institution_server.update_attributes(url: new_url)
      default.reload.url.should_not eql(new_url)
    end

    it "when the secret of the default server is updated, doesn't update the other servers" do
      new_secret = default.secret + "2"
      default.update_attributes(secret: new_secret)
      institution_server.reload.url.should_not eql(new_secret)
    end
  end

  # This is a model from BigbluebuttonRails, but we have permissions set in cancan for it,
  # so we test them here.
  describe "abilities", :abilities => true do
    subject { ability }
    let(:user) { nil }
    let(:ability) { Abilities.ability_for(user) }
    let(:target) { FactoryGirl.create(:bigbluebutton_server) }

    context "a superuser", :user => "superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      it { should be_able_to_do_everything_to(target) }
    end

    context "a normal user", :user => "normal" do
      let(:user) { FactoryGirl.create(:user) }
      it { should_not be_able_to_do_anything_to(target) }
    end

    context "an anonymous user", :user => "anonymous" do
      it { should_not be_able_to_do_anything_to(target) }
    end
  end

end
