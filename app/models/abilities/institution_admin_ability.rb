# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module Abilities

  # Users that are admins of their institutions have some privileged permissions in objects
  # related to their institution.
  class InstitutionAdminAbility < MemberAbility

    alias :super_register :register_abilities
    def register_abilities(user)
      super_register(user)

      # TODO: move checks for disabled/unapproved resources to their own methods,
      #   as is done in MemberAbility

      # Things an institutional admin can make in the users from his institution
      # * Update the user's info
      # * Approve (and change their attribute `:approved`) and confirm
      # * Give permission to record (change the attribute `:can_record`)
      # * Manage users (generic, doesn't specify which attributes)
      # * Register new users
      can [:edit, :update, :approve, :manage_user,
           :give_recording_rights, :confirm, :update_password], User do |target|
        target.institution.present? && !target.disabled &&
          target.institution.admins.include?(user)
      end
      can [:new, :create], User do
        user.institution.present? && !user.institution.full?
      end

      # Institutional admins can access the manage lists of spaces and users in their institution
      can [:users, :spaces], :manage do
        !user.institution.nil? && user.institution.admins.include?(user)
      end

      # Institutional admins can access these actions in their institution
      can :index, Institution
      can [:show, :users, :spaces], Institution do
        !user.institution.nil? && user.institution.admins.include?(user)
      end

      # Institutional admins can edit their institution's users
      can [:show, :edit, :update], Profile do |profile|
        !profile.user.institution.nil? && profile.user.institution.admins.include?(user)
      end

      # Can create no matter if the site has creation disabled
      can [:create, :new], Space

      # Institutional admins can edit their institution's spaces and all the resources
      # associated with it, exactly an admin of the space would
      can [:show, :destroy, :edit, :approve, :disapprove, :update, :user_permissions,
           :webconference_options, :webconference, :recordings], Space do |space|
        !space.disabled &&
          is_institution_admin_of_space(user, space)
      end
      can :manage, News do |news|
        space = news.space
        !space.disabled &&
          is_institution_admin_of_space(user, space)
      end
      can [:show, :edit, :update], Permission do |perm|
        case perm.subject_type
        when "Space"
          space = perm.subject
          !space.disabled &&
            is_institution_admin_of_space(user, space)
        when "Institution"
          admins = perm.subject.admins
          admins.include?(user)
        else
          false
        end
      end
      can [:show, :create, :reply_post], Post do |post|
        space = post.space
        !space.disabled &&
          is_institution_admin_of_space(user, space)
      end
      can :manage, Attachment do |attach|
        space = attach.space
        !space.disabled &&
          space.repository? &&
          is_institution_admin_of_space(user, space)
      end
      can [:end, :join_options, :create_meeting, :fetch_recordings], BigbluebuttonRoom do |room|
        space = room.owner
        room.owner_type == "Space" &&
          !space.disabled &&
          is_institution_admin_of_space(user, space)
      end
      can :record_meeting, BigbluebuttonRoom do |room|
        space = room.owner
        user.can_record &&
          room.owner_type == "Space" &&
          !space.disabled &&
          is_institution_admin_of_space(user, space)
      end
      can [:play, :update, :space_edit, :space_show], BigbluebuttonRecording do |recording|
        room = recording.room
        room && room.owner_type == "Space" &&
          !room.owner.disabled &&
          is_institution_admin_of_space(user, room.owner)
      end

      def is_institution_admin_of_space(user, space)
        !space.institution.nil? && space.institution.admins.include?(user)
      end
    end

  end

end
