# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe CustomBigbluebuttonRecordingsController do
  render_views

  describe "#update" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

    # This is an adapted copy of the same test done for this controller action in BigbluebuttonRails
    # we just check that the method 'permit' is being called with the correct parameters and assume
    # it does what it should.
    context "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
      let(:params) { { :controller => 'CustomBigbluebuttonRoomsController', :action => :update, :bigbluebutton_recording => attrs } }

      context "for a superuser" do
        let(:user) { FactoryGirl.create(:superuser) }
        before(:each) { login_as(user) }

        let(:allowed_params) {
          [ :description ]
        }
        it {
          BigbluebuttonRecording.stub(:find_by_recordid).and_return(recording)
          recording.stub(:update_attributes).and_return(true)
          attrs.stub(:permit).and_return(attrs)
          params[:id] = recording.recordid
          controller.stub(:params).and_return(params)

          put :update, :id => recording.to_param, :bigbluebutton_recording => attrs
          attrs.should have_received(:permit).with(*allowed_params)
        }
      end

      context "for a normal user" do
        let(:user) { FactoryGirl.create(:user) }
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => user.bigbluebutton_room) }
        before(:each) { login_as(user) }

        let(:allowed_params) {
          [ :description ]
        }
        it {
          BigbluebuttonRecording.stub(:find_by_recordid).and_return(recording)
          recording.stub(:update_attributes).and_return(true)
          attrs.stub(:permit).and_return(attrs)
          params[:id] = recording.recordid
          controller.stub(:params).and_return(params)

          put :update, :id => recording.to_param, :bigbluebutton_recording => attrs
          attrs.should have_received(:permit).with(*allowed_params)
        }
      end
    end
  end

  skip "#publish"

  describe "#unpublish" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording, room: room) }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let(:server_return) { lambda {true} }

    before do
      login_as(user)

      # For the seconf block of tests
      if defined?(space) && !user.superuser?
        space.add_member!(user, 'Admin')
      end

      # Mock BBB server message
      BigbluebuttonRecording.stub(:find_by_recordid).and_return(recording)
      recording.server.stub(:send_publish_recordings) { server_return.call }

      post :unpublish, id: recording.recordid
      recording.reload
    end

    context "if it's a superuser unpublishing" do
      let(:user) { FactoryGirl.create(:superuser) }

      context "his recording" do
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: user) }

        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.unpublish.success')) }
      end

      context "a recording in a space" do
        let(:space) { FactoryGirl.create(:space) }
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: space) }

        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.unpublish.success')) }
      end

      context "a recording via manage interface" do
        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.unpublish.success')) }
      end

    end

    context "if is a normal user unpublishing" do
      let(:user) { FactoryGirl.create(:user) }

      context "his recording" do
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: user) }

        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.unpublish.success')) }
      end

      context "his recordings, but there is a server error" do
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: user) }

        let(:server_return) { lambda {raise BigBlueButton::BigBlueButtonException.new('Server error')} }
        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to('Server error') }
      end

      context "a recording in a space he is an admin" do
        let(:space) { FactoryGirl.create(:space) }
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: space) }

        it { should redirect_to bigbluebutton_recording_path(recording) }
        it { should set_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.unpublish.success')) }
      end
    end
  end

  skip "#destroy"

  describe "#play" do
    let(:user) { FactoryGirl.create(:superuser) }
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let!(:format) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording) }

    before { login_as(user) }

    context "if there is a parameter 'name' in the URL" do
      before { get :play, id: recording.to_param, name: "custom_rec_name" }
      it { should respond_with(:redirect) }
      it { should redirect_to "#{format.url}?name=custom_rec_name" }
    end

    context "if there is no parameter 'name' in the URL" do
      before { get :play, id: recording.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to format.url }
    end

    context "with other random parameters in the URL" do
      before { get :play, id: recording.to_param, anything_weird: "test" }
      it { should respond_with(:redirect) }
      it { should redirect_to format.url }
    end

    context "doesn't break if there's no playback format" do
      before {
        format.destroy
        get :play, id: recording.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recording_path(recording) }
    end
  end

  describe "abilities", :abilities => true do
    render_views(false)

    context "for a superuser", :user => "superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      let(:hash_with_server) { { :server_id => recording.server.id } }
      let(:hash) { hash_with_server.merge!(:id => recording.to_param) }
      before(:each) { login_as(user) }

      it { should allow_access_to(:index) }

      # the permissions are always the same, doesn't matter the type of recording, so
      # we have them all in this common method
      shared_examples_for "a superuser accessing any webconf recording" do
        it { should allow_access_to(:show, hash) }
        it { should allow_access_to(:edit, hash) }
        it { should allow_access_to(:update, hash).via(:put) }
        it { should allow_access_to(:destroy, hash).via(:delete) }
        it { should allow_access_to(:play, hash) }
        it { should allow_access_to(:publish, hash).via(:post) }
        it { should allow_access_to(:unpublish, hash).via(:post) }
      end

      context "in a recording of his room" do
        let(:recording) {
          room = user.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "a superuser accessing any webconf recording"
      end

      context "in a recording of another user's room" do
        let(:recording) {
          room = FactoryGirl.create(:superuser).bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "a superuser accessing any webconf recording"
      end

      context "in a recording of a public space" do
        let(:space) { FactoryGirl.create(:space, :public => true) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a superuser accessing any webconf recording"
        end

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing any webconf recording"
        end
      end

      context "in a recording of a private space" do
        let(:space) { FactoryGirl.create(:space, :public => false) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a superuser accessing any webconf recording"
        end

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing any webconf recording"
        end
      end
    end

    context "for a normal user", :user => "normal" do
      let(:user) { FactoryGirl.create(:user) }
      let(:hash_with_server) { { :server_id => recording.server.id } }
      let(:hash) { hash_with_server.merge!(:id => recording.to_param) }
      before(:each) { login_as(user) }

      it { should_not allow_access_to(:index) }

      # most of the permissions are the same for any room
      shared_examples_for "a normal user accessing any webconf recording" do
        it { should_not allow_access_to(:destroy, hash).via(:delete) }
        it { should_not allow_access_to(:publish, hash).via(:post) }
        it { should_not allow_access_to(:unpublish, hash).via(:post) }
      end

      context "in a recording of his room" do
        let(:recording) {
          room = user.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it { should_not allow_access_to(:destroy, hash).via(:delete) }
        it { should_not allow_access_to(:publish, hash).via(:post) }
        it { should allow_access_to(:unpublish, hash).via(:post) }
        it { should allow_access_to(:play, hash) }
      end

      context "in a recording of another user's room" do
        let(:recording) {
          room = FactoryGirl.create(:user).bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "a normal user accessing any webconf recording"
        it { should_not allow_access_to(:show, hash) }
        it { should_not allow_access_to(:play, hash) }
      end

      context "in a recording of a public space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: true) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should allow_access_to(:play, hash) }
        end

        context "he is not a member of" do
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should allow_access_to(:play, hash) }
        end

        context "he is an admin of" do
          before { space.add_member!(user, 'Admin') }

          it { should_not allow_access_to(:destroy, hash).via(:delete) }
          it { should_not allow_access_to(:publish, hash).via(:post) }
          it { should allow_access_to(:unpublish, hash).via(:post) }
          it { should allow_access_to(:play, hash) }
        end
      end

      context "in a recording of a private space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: false) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should allow_access_to(:play, hash) }
        end

        context "he is not a member of" do
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should_not allow_access_to(:play, hash) }
        end

        context "he is an admin of" do
          before { space.add_member!(user, 'Admin') }

          it { should_not allow_access_to(:destroy, hash).via(:delete) }
          it { should_not allow_access_to(:publish, hash).via(:post) }
          it { should allow_access_to(:unpublish, hash).via(:post) }
          it { should allow_access_to(:play, hash) }
        end
      end

    end

    context "for an anonymous user", :user => "anonymous" do
      let(:hash_with_server) { { :server_id => recording.server.id } }
      let(:hash) { hash_with_server.merge!(:id => recording.to_param) }

      it { should require_authentication_for(:index) }

      shared_examples_for "an anonymous user accessing any webconf recording" do
        it { should require_authentication_for(:show, hash) }
        it { should require_authentication_for(:edit, hash) }
        it { should require_authentication_for(:update, hash).via(:put) }
        it { should require_authentication_for(:destroy, hash).via(:delete) }
        it { should_not require_authentication_for(:play, hash) }
        it { should require_authentication_for(:publish, hash).via(:post) }
        it { should require_authentication_for(:unpublish, hash).via(:post) }
      end

      context "in a user room" do
        let(:recording) {
          room = FactoryGirl.create(:superuser).bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "an anonymous user accessing any webconf recording"
        it { should_not allow_access_to(:play, hash) }
      end

      context "in the room of public space" do
        let(:space) { FactoryGirl.create(:space_with_associations, :public => true) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "an anonymous user accessing any webconf recording"
        it { should allow_access_to(:play, hash) }
      end

      context "in the room of private space" do
        let(:space) { FactoryGirl.create(:space_with_associations, :public => false) }
        let(:recording) {
          room = space.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "an anonymous user accessing any webconf recording"
        it { should_not allow_access_to(:play, hash) }
      end
    end

    context "for an institutional admin", :user => "institutionalAdmin" do
      let(:institution) { FactoryGirl.create(:institution) }
      let(:institution_other) { FactoryGirl.create(:institution) }
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let(:room_other) { FactoryGirl.create(:bigbluebutton_room) }
      let(:user) { FactoryGirl.create(:user, :institution => institution) }
      before { institution.add_member!(user, 'Admin') }
      let(:hash_with_server) { { :server_id => recording.server.id } }
      let(:hash) { hash_with_server.merge!(:id => recording.to_param) }
      before(:each) { login_as(user) }

      it { should allow_access_to(:index) }

      # the permissions are always the same, doesn't matter the type of recording, so
      # we have them all in this common method
      shared_examples_for "a superuser accessing any webconf recording" do
        it { should allow_access_to(:show, hash) }
        it { should allow_access_to(:edit, hash) }
        it { should allow_access_to(:update, hash).via(:put) }
        it { should allow_access_to(:destroy, hash).via(:delete) }
        it { should allow_access_to(:play, hash) }
        it { should allow_access_to(:publish, hash).via(:post) }
        it { should allow_access_to(:unpublish, hash).via(:post) }
      end

      shared_examples_for "a normal user accessing any webconf recording" do
        it { should_not allow_access_to(:destroy, hash).via(:delete) }
        it { should_not allow_access_to(:publish, hash).via(:post) }
        it { should_not allow_access_to(:unpublish, hash).via(:post) }
      end

      context "in a recording of his room" do
        let(:recording) {
          room = user.bigbluebutton_room
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }
        it_should_behave_like "a superuser accessing any webconf recording"
      end

      context "in a recording of another user's room" do
        let(:recording) {
          FactoryGirl.create(:bigbluebutton_recording, :room => room_other)
        }
        it_should_behave_like "a normal user accessing any webconf recording"
        it { should_not allow_access_to(:show, hash) }
        it { should_not allow_access_to(:play, hash) }
      end

      context "in a recording of a public space not from his institution" do
        let(:space) { FactoryGirl.create(:space, :institution => institution_other, :bigbluebutton_room => room_other, :public => true) }
        let(:recording) {
          FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should_not allow_access_to(:show, hash) }
          it { should allow_access_to(:play, hash) }
        end

        context "he is not a member of" do
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should_not allow_access_to(:show, hash) }
          it { should allow_access_to(:play, hash) }
        end
      end

      context "in a recording of a private space not from his institution" do
        let(:space) { FactoryGirl.create(:space, :institution => institution_other, :bigbluebutton_room => room_other, :public => false) }
        let(:recording) {
          FactoryGirl.create(:bigbluebutton_recording, :room => room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should_not allow_access_to(:show, hash) }
          it { should_not allow_access_to(:play, hash) }
        end

        context "he is not a member of" do
          it_should_behave_like "a normal user accessing any webconf recording"
          it { should_not allow_access_to(:show, hash) }
          it { should_not allow_access_to(:play, hash) }
        end
      end

      context "in a recording of a public space from his institution" do
        let(:space) { FactoryGirl.create(:space, :institution => institution, :bigbluebutton_room => room, :public => true) }
        let(:recording) {
          FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a superuser accessing any webconf recording"
        end

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing any webconf recording"
        end
      end

      context "in a recording of a private space from his institution" do
        let(:space) { FactoryGirl.create(:space, :institution => institution, :bigbluebutton_room => room, :public => false) }
        let(:recording) {
          FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room)
        }

        context "he is a member of" do
          before { space.add_member!(user) }
          it_should_behave_like "a superuser accessing any webconf recording"
        end

        context "he is not a member of" do
          it_should_behave_like "a superuser accessing any webconf recording"
        end
      end
    end
  end
end
