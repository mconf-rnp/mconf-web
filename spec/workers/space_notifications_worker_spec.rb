# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe SpaceNotificationsWorker, type: :worker do
  let(:worker) { SpaceNotificationsWorker }

  it "uses the queue :space_notifications" do
    worker.instance_variable_get(:@queue).should eql(:space_notifications)
  end

  describe "#perform" do

    context "if the site requires approval" do
      before {
        Site.current.update_attributes(require_space_approval: true)
      }

      context "notifies admins when spaces need approval" do

        context "for multiple global admins and a space with no institution" do
          let(:space) { FactoryGirl.create(:space, institution: nil, approved: false) }
          let!(:space_admin) { FactoryGirl.create(:user, institution: nil) }

          let!(:admin1) { FactoryGirl.create(:superuser) }
          let!(:admin2) { FactoryGirl.create(:superuser) }

          let(:activity) { RecentActivity.last }
          let(:admin_ids) { User.where(superuser: true).ids }

          before(:each) {
            space.add_member!(space_admin, 'Admin')
            space.new_activity('create', space_admin)
            worker.perform
          }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(1) }
          it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity.id, admin_ids) }
        end

        context "for multiple spaces with institutions" do
          let(:institution) { FactoryGirl.create(:institution, require_space_approval: true) }
          let(:space_admin) { FactoryGirl.create(:user, institution: institution) }

          let(:space1) { FactoryGirl.create(:space, institution: institution, approved: false) }
          let(:space2) { FactoryGirl.create(:space, institution: institution, approved: false) }

          let!(:activity1) { space1.new_activity('create', space_admin) }
          let!(:activity2) { space2.new_activity('create', space_admin) }

          let(:global_admin) { FactoryGirl.create(:superuser) }
          let(:admin_ids) { institution.admin_ids }

          before(:each) {
            institution.add_member!(FactoryGirl.create(:user), 'Admin')

            space1.add_member!(space_admin, 'Admin')
            space2.add_member!(space_admin, 'Admin')

            worker.perform
          }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(2) }
          it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity1.id, admin_ids) }
          it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity2.id, admin_ids) }
        end

        context "for multiple spaces some with institutions, some don't" do
          let(:institution) { FactoryGirl.create(:institution, require_space_approval: true) }
          let!(:space_admin) { FactoryGirl.create(:user, institution: institution) }
          let!(:space_admin_no_inst) { FactoryGirl.create(:user, institution: nil) }

          let(:space1) { FactoryGirl.create(:space, institution: institution, approved: false) }
          let(:space2) { FactoryGirl.create(:space, institution: nil, approved: false) }

          let!(:activity1) { space1.new_activity('create', space_admin) }
          let!(:activity2) { space2.new_activity('create', space_admin_no_inst) }

          let!(:admin1) { FactoryGirl.create(:superuser) }
          let!(:admin2) { FactoryGirl.create(:superuser) }
          let!(:global_admin_ids) { User.where(superuser: true).ids }

          before(:each) {
            institution.add_member!(FactoryGirl.create(:user), 'Admin')

            space1.add_member!(space_admin, 'Admin')
            space2.add_member!(space_admin_no_inst, 'Admin')

            worker.perform
          }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(2) }
          it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity1.id, institution.admin_ids) }
          it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity2.id, global_admin_ids) }
        end

        context "ignores space not approved but that already had their notification sent" do
          let!(:admin) { FactoryGirl.create(:user) }
          let!(:space1) { FactoryGirl.create(:space, institution: nil, approved: false) }
          let!(:space2) { FactoryGirl.create(:space, institution: nil, approved: false) }
          before {
            space1.add_member!(admin, 'Admin')
            space1.new_activity('create', admin)
            space2.add_member!(admin, 'Admin')
            space2.new_activity('create', admin)
            RecentActivity.where(key: 'space.create', trackable_id: [space1.id, space2.id])
              .each { |act|
                act.update_attributes(notified: true)
              }
          }
          before(:each) { worker.perform }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(0) }
        end

        context "ignores spaces that were already approved" do
          let!(:admin) { FactoryGirl.create(:user) }
          let!(:space1) { FactoryGirl.create(:space, approved: true) }
          let!(:space2) { FactoryGirl.create(:space, approved: true) }

          before(:each) {
            space1.add_member!(admin, 'Admin')
            space1.new_activity('create', admin)
            space2.add_member!(admin, 'Admin')
            space2.new_activity('create', admin)
            worker.perform
          }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(0) }
        end

        context "when the target space cannot be found" do
          let!(:admin) { FactoryGirl.create(:user) }
          let!(:space1) { FactoryGirl.create(:space, approved: false) }

          before(:each) {
            space1.add_member!(admin, 'Admin')
            space1.new_activity('create', admin)

            activity = RecentActivity.where(key: 'space.create', trackable: space1).first
            activity.update_attribute(:trackable_id, nil)
            worker.perform
          }

          it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(0) }
        end
      end

      context "notifies space admins when the space is approved" do

        context "for multiple admins" do
          let(:approver) { FactoryGirl.create(:superuser) }
          let(:space1) { FactoryGirl.create(:space, approved: true) }
          let(:activity1) { RecentActivity.where(key: 'space.approved', trackable_id: space1.id).first }
          let(:space2) { FactoryGirl.create(:space, approved: true) }
          let(:activity2) { RecentActivity.where(key: 'space.approved', trackable_id: space2.id).first }

          before {
            space1.add_member!(FactoryGirl.create(:user), 'Admin')
            space1.new_activity('create', space1.admins.first)
            space1.approve!
            space1.create_approval_notification(approver)
            space2.add_member!(FactoryGirl.create(:user), 'Admin')
            space2.new_activity('create', space2.admins.first)
            space2.approve!
            space2.create_approval_notification(approver)
            worker.perform
          }

          it { expect(SpaceApprovedSenderWorker).to have_queue_size_of_at_least(2) }
          it { expect(SpaceApprovedSenderWorker).to have_queued(activity1.id) }
          it { expect(SpaceApprovedSenderWorker).to have_queued(activity2.id) }
        end

        context "ignores spaces that were not approved yet" do
          let!(:space1) { FactoryGirl.create(:space, approved: false) }
          let!(:space2) { FactoryGirl.create(:space, approved: false) }

          before(:each) {
            space1.add_member!(FactoryGirl.create(:user), 'Admin')
            space2.add_member!(FactoryGirl.create(:user), 'Admin')
            worker.perform
          }

          it { expect(SpaceApprovedSenderWorker).to have_queue_size_of(0) }
        end

      end
    end

    context "if the site does not require approval" do
      before {
        Site.current.update_attributes(require_registration_approval: false)
      }

      context "doesn't notify admins when spaces don't need approval" do
        let!(:admin1) { FactoryGirl.create(:superuser) }
        let!(:admin2) { FactoryGirl.create(:superuser) }
        let!(:space1) { FactoryGirl.create(:space, approved: false) }
        let!(:space2) { FactoryGirl.create(:space, approved: false) }

        before(:each) {
          space1.new_activity('create', FactoryGirl.create(:user))
          space2.new_activity('create', FactoryGirl.create(:user))

          worker.perform
        }

        it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(0) }
      end

      context "doesn't notify insitutional admins when spaces don't need approval" do
        let!(:space_admin) { FactoryGirl.create(:user) }
        let!(:institution) { space_admin.institution }

        let!(:space1) { FactoryGirl.create(:space, institution: institution, approved: false) }
        let!(:space2) { FactoryGirl.create(:space, institution: institution, approved: false) }

        before(:each) {
          institution.add_member!(FactoryGirl.create(:user), 'Admin')
          space1.new_activity('create', space_admin)
          space2.new_activity('create', space_admin)  

          worker.perform
        }

        it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(0) }
      end

      context "does notify global admins when institution needs approval" do
        let!(:admin1) { FactoryGirl.create(:superuser) }
        let!(:admin2) { FactoryGirl.create(:superuser) }
        let(:admin_ids) { User.where(superuser: true).ids }

        let(:institution) { FactoryGirl.create(:institution) }

        let(:space1) { FactoryGirl.create(:space, institution: institution, approved: false) }
        let(:space2) { FactoryGirl.create(:space, institution: institution, approved: false) }

        let(:activity1) { space1.new_activity('create', FactoryGirl.create(:user)) }
        let(:activity2) { space2.new_activity('create', FactoryGirl.create(:user)) }

        before(:each) {
          institution.update_attribute(:require_space_approval, true)
          activity1
          activity2

          worker.perform
        }

        it { expect(SpaceNeedsApprovalSenderWorker).to have_queue_size_of(2) }
        it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity1.id, admin_ids) }
        it { expect(SpaceNeedsApprovalSenderWorker).to have_queued(activity2.id, admin_ids) }
      end

      context "notifies space admins of approval if institution is moderated" do
        let(:approver) { FactoryGirl.create(:user) }
        let(:institution) { approver.institution }
        let(:space1) { FactoryGirl.create(:space, institution: institution) }
        let(:activity1) { RecentActivity.where(key: 'space.approved', trackable_id: space1.id).first }
        let(:space2) { FactoryGirl.create(:space, institution: institution) }
        let(:activity2) { RecentActivity.where(key: 'space.approved', trackable_id: space2.id).first }

        before {
          institution.update_attribute(:require_space_approval, true)

          space1.add_member!(FactoryGirl.create(:user), 'Admin')
          space1.new_activity('create', space1.admins.first)
          space1.approve!
          space1.create_approval_notification(approver)

          space2.add_member!(FactoryGirl.create(:user), 'Admin')
          space2.new_activity('create', space2.admins.first)
          space2.approve!
          space2.create_approval_notification(approver)

          worker.perform
        }

        it { expect(SpaceApprovedSenderWorker).to have_queue_size_of_at_least(2) }
        it { expect(SpaceApprovedSenderWorker).to have_queued(activity1.id) }
        it { expect(SpaceApprovedSenderWorker).to have_queued(activity2.id) }
      end

    end

  end

end
