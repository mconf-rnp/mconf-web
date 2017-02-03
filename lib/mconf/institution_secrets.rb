# To use different secrets for different institutions, we need to adjust some things
# in BigbluebuttonRails. This module contains everything that needs to be changed.

# require 'active_support/concern'

module Mconf::InstitutionSecrets

  def self.configure
    BigbluebuttonRoom.class_eval do
      include Mconf::InstitutionSecrets::Shared
    end

    BigbluebuttonMeeting.class_eval do
      include Mconf::InstitutionSecrets::Shared
    end

    BigbluebuttonRecording.class_eval do
      include Mconf::InstitutionSecrets::Shared
    end

    BigbluebuttonRails::BackgroundTasks.instance_eval do
      class << self
        alias_method :old_update_recordings, :update_recordings
      end

      def update_recordings
        old_update_recordings

        default = BigbluebuttonServer.default
        Institution.find_each do |institution|
          Rails.logger.info "BackgroundTasks: Updating recordings for the institution #{institution.name}"
          unless institution.secret.blank?
            Rails.logger.info "BackgroundTasks: #{institution.name} has secret #{institution.secret}"
            server = BigbluebuttonServer.new(url: default.url, secret: institution.secret)
            begin

              # Note: setting `full_sync` to true only works because `server` is not stored in
              # the database, so when bigbluebutton_rails tries to remove all recordings in this
              # server that are not in the response of this getRecordings, it will not remove
              # anything (the server's id is null, so the select returns nothing).
              server.fetch_recordings(nil, true)

              Rails.logger.info "BackgroundTasks: Successfully updated the list of recordings for institution #{institution.name} (#{server.url}, #{server.secret})"
            rescue Exception => e
              Rails.logger.info "BackgroundTasks: Failure fetching recordings for institution #{institution.name} (#{server.url}, #{server.secret})"
              Rails.logger.info "BackgroundTasks: #{e.inspect}"
              Rails.logger.info "BackgroundTasks: #{e.backtrace.join("\n")}"
            end
          end
        end
      end
    end
  end

  module Shared
    extend ActiveSupport::Concern

    # Overrides the method to search for the target server based on the institution
    # that owns this room
    def server
      server_considering_secret
    end

    def server_considering_secret
      default = BigbluebuttonServer.default
      selected = BigbluebuttonServer.new(url: default.url, secret: default.secret)

      # get the associated objects depending on which type of model this is
      if self.is_a?(BigbluebuttonRoom)
        Rails.logger.info "Checking server for the room #{self.meetingid} (#{self.create_time})"
        meeting = self.get_current_meeting
        owner = self.try(:owner)
        institution = owner.try(:institution)
      elsif self.is_a?(BigbluebuttonMeeting)
        Rails.logger.info "Checking server for the meeting #{self.meetingid} (#{self.create_time})"
        meeting = self
        owner = self.try(:room).try(:owner)
        institution = owner.try(:institution)
      else # recording
        Rails.logger.info "Checking server for the recording #{self.recordid} (#{self.meetingid})"
        owner = self.try(:room).try(:owner)
        institution = owner.try(:institution)
      end

      # if there's a meeting running, use the same server that was used to create it
      if meeting.present? && !meeting.server_secret.blank? && !meeting.ended?
        selected.secret = meeting.server_secret
        Rails.logger.info "Selected the server set in the meeting (#{selected.url}, #{selected.secret})"

      # if the object is associated with an institution, use its secret
      elsif owner.present? && institution.present? && !institution.secret.blank?
        selected.secret = institution.secret
        Rails.logger.info "Selected the server set in the institution (#{selected.url}, #{selected.secret})"

      # no meeting and no institution with secret, use the default server
      else
        Rails.logger.info "Selected the default server (#{selected.url}, #{selected.secret})"
      end

      selected
    end

  end
end
