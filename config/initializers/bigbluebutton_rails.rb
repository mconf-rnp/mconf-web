# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

BigbluebuttonRails.configure do |config|
  config.guest_support = true

  # New method to select a server for a room
  config.select_server = Proc.new do |room, api_method=nil|
    room.server_considering_secret(api_method)
  end

  # Set the invitation URL to the full URL of the room
  config.get_invitation_url = Proc.new do |room|
    host = Site.current.domain_with_protocol
    Rails.application.routes.url_helpers.join_webconf_url(room, host: host)
  end

  # Add custom metadata to all create calls
  config.get_dynamic_metadata = Proc.new do |room|
    host = Site.current.domain_with_protocol
    meta = {
      "mconfweb-url" => Rails.application.routes.url_helpers.root_url(host: host),
      "mconfweb-room-type" => room.try(:owner).try(:class).try(:name)
    }

    institution = room.try(:owner).try(:institution)
    if institution.present?
      name = institution.try(:name) || ""
      acronym = institution.try(:acronym) || ""
      meta.merge!(
        {
          "mconfweb-institution-name" => name,
          "mconfweb-institution-acronym" => acronym
        }
      )
    end

    meta
  end
end

Rails.application.config.to_prepare do

  BigbluebuttonRoom.class_eval do

    # Returns whether the `user` created the current meeting on this room
    # or not. Has to be called after a `fetch_meeting_info`, otherwise will always
    # return false.
    def user_created_meeting?(user)
      meeting = get_current_meeting()
      unless meeting.nil?
        meeting.created_by?(user)
      else
        false
      end
    end

    # Currently room is public only if belonging to a public space
    def public?
      owner_type == "Space" && Space.where(:id => owner_id, :public => true).present?
    end

    # Selects a server to use with this room considering institution secrets.
    # If the room has an institution, it has to use a server with the salt created by
    # the institution.
    def server_considering_secret(api_method=nil)
      default = BigbluebuttonServer.default

      # get the associated objects depending on which type of model this is
      Rails.logger.info "Checking server for the room #{self.meetingid} (#{self.create_time})"
      meeting = self.get_current_meeting
      owner = self.try(:owner)
      institution = owner.try(:institution)

      # if there's a meeting running, use the same server that was used to create it
      if meeting.present? && !meeting.server_secret.blank? && !meeting.ended?
        selected = BigbluebuttonServer.new(url: default.url, secret: meeting.server_secret)
        Rails.logger.info "Selected the server set in the meeting (#{selected.url}, #{selected.secret})"

      # if the object is associated with an institution, use its secret
      elsif owner.present? && institution.present?#  && !institution.secret.blank?
        selected = institution.server
        Rails.logger.info "Selected the server set in the institution (#{selected.url}, #{selected.secret})"

      # no meeting and no institution with secret, use the default server
      else
        selected = default
        Rails.logger.info "Selected the default server (#{selected.url}, #{selected.secret})"
      end

      selected
    end
  end

  BigbluebuttonMeeting.instance_eval do
    include PublicActivity::Model

    tracked only: [:create], owner: :room,
      recipient: -> (ctrl, model) { model.room.owner },
      params: {
        creator_id: -> (ctrl, model) {
          model.try(:creator_id)
        },
        creator_username: -> (ctrl, model) {
          id = model.try(:creator_id)
          user = User.find_by(id: id)
          user.try(:username)
        }
      }
  end

  BigbluebuttonRecording.instance_eval do
    include UpdateInstitutionRecordingsDisk
  end

  BigbluebuttonServer.instance_eval do

    # When the URL of the default server changes, change the URL of all institution servers.
    after_update if: :url_changed? do
      if BigbluebuttonServer.default.id == self.id
        BigbluebuttonServer.where.not(id: self.id).update_all(url: self.url)
      end
    end

  end
end
