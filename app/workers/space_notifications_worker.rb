# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# Mostly for space approvals, find the newly created spaces and prepare notification objects
class SpaceNotificationsWorker < BaseWorker
  @queue = :space_notifications

  def self.perform
    notify_admins_of_spaces_pending_approval
    notify_space_admins_after_approved
  end

  # Gets all spaces that were created and need approval, then schedules a worker to notify the global admins
  def self.notify_admins_of_spaces_pending_approval
    # The Activities with keys space.created are used to inform the admins that a new space was created.
    activities = RecentActivity
      .where(trackable_type: 'Space', notified: [nil, false], key: 'space.create')

    global_admins = User.where(superuser: true).ids

    activities.each do |activity|
      # If space has already been approved or doesn't require approval,
      # we don't need to send the notification.
      space = Space.find_by(id: activity.trackable_id)
      if space.try(:approved?) || !space.try(:require_approval?)
        activity.update_attribute(:notified, true)
      elsif space
        recipients = []
        if space.institution.present? && !space.institution.admin_ids.empty?
          recipients = space.institution.admin_ids
        elsif !global_admins.empty?
          recipients = global_admins
        end

        if recipients.any?
          Resque.enqueue(SpaceNeedsApprovalSenderWorker, activity.id, recipients)
        end
      end
    end
  end

  # Finds all spaces that were approved but not notified yet and schedules a worker.
  def self.notify_space_admins_after_approved
    activities = RecentActivity
      .where trackable_type: 'Space', key: 'space.approved', notified: [nil, false]
    activities.each do |activity|
      Resque.enqueue(SpaceApprovedSenderWorker, activity.id)
    end
  end

end
