require 'spec_helper'

describe Institution do
  let(:institution) { FactoryGirl.create(:institution) }

  it "creates a new instance given valid attributes" do
    FactoryGirl.build(:institution).should be_valid
  end

  it { should have_many(:permissions).dependent(:destroy) }
  it { should have_many(:spaces) }
  it { should have_many(:users) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of(:permalink) }

  describe ".spaces" do
    let(:target) { FactoryGirl.create(:institution) }
    before {
      FactoryGirl.create(:space, :institution => target)
      FactoryGirl.create(:space, :institution => target)
    }

    it { target.spaces.size.should be(2) }
    it {
      expect {
        FactoryGirl.create(:space, :institution => target)
      }.to change(target.spaces, :count).by(+1)
    }
  end

  it ".roles"

  describe ".search" do
    it "returns an empty array if name is blank"

    before(:each) do
      FactoryGirl.create(:institution, :name => 'Black Sabbath', :acronym => 'BS')
      FactoryGirl.create(:institution, :name => 'National Acrobats Association', :acronym => 'NAA')
      FactoryGirl.create(:institution, :name => 'National Snooping Agency', :acronym => 'NSA')
      FactoryGirl.create(:institution, :name => 'Never Say Abba', :acronym => 'NSA')
      FactoryGirl.create(:institution, :name => 'Alices and Bobs', :acronym => 'A&Bs')
    end

    it { Institution.search('RNP').should be_empty }
    it { Institution.search('ABBA').count.should be(2) }
    it { Institution.search('NSA').count.should be(2) }
    it { Institution.search('Nat').count.should be(2) }
    it { Institution.search('Black Sabbath').count.should be(1) }
    it { Institution.search('BS').count.should be(2) }
  end

  describe ".correct_duplicate" do
    let(:original) { FactoryGirl.create(:institution, :name => 'National Snooping Agency', :acronym => 'NSA') }
    let(:copy) { FactoryGirl.create(:institution, :name => 'NSA', :acronym => 'NSA') }
    let(:admin){ FactoryGirl.create(:user, :username => 'thecopyadmin')}
    before :each do
      original.add_member!(FactoryGirl.create(:user))
      copy.add_member!(FactoryGirl.create(:user))
      copy.add_member!(admin, 'Admin')
    end
    subject { Institution.correct_duplicate(original, copy) }

    it { expect {subject}.to change(Institution, :count).by(-1) }
    it { expect {subject}.to change(original.users, :count).by(+2) }
    it { expect {subject}.to change(copy.users, :count).by(-2) }
    it { original.admins.include? admin }
  end

  it ".find_or_create_by_name_or_acronym"

  it "#approved_users"

  describe "#full?" do
    let(:target) { FactoryGirl.create(:institution) }

    context "false if the user limit is nil" do
      before { target.update_attributes(:user_limit => nil) }
      it { target.full?.should be_falsey }
    end

    context "false if the user limit is an empty string" do
      before { target.update_attributes(:user_limit => "") }
      it { target.full?.should be_falsey }
    end

    context "false if the number of approved users has not reached the limit yet" do
      before {
        FactoryGirl.create(:user, :institution => target)
        target.update_attributes(:user_limit => 2)
      }
      it { target.full?.should be_falsey }
    end

    context "true if the number of approved users is equal the limit" do
      before {
        FactoryGirl.create(:user, :institution => target)
        target.update_attributes(:user_limit => 1)
      }
      it { target.full?.should be_truthy }
    end

    context "true if the number of approved users is bigger than the limit" do
      before {
        FactoryGirl.create(:user, :institution => target)
        FactoryGirl.create(:user, :institution => target)
        target.update_attributes(:user_limit => 1)
      }
      it { target.full?.should be_truthy }
    end
  end

  it "#users_that_can_record"
  it "#can_record_full?"
  it "#admins"

  describe "#disk_usage_ratio and #exceeded_disk_quota?" do
    let(:institution) { FactoryGirl.create(:institution, recordings_disk_quota: quota, recordings_disk_used: used) }

    context '100%' do
      let(:quota) { 1001 }
      let(:used) { 1001 }

      it { institution.disk_usage_ratio.should eq(1) }
      it { institution.exceeded_disk_quota?.should be(true) }
    end

    context '50%' do
      let(:quota) { 500 }
      let(:used) { 250 }

      it { institution.disk_usage_ratio.should eq(0.5) }
      it { institution.exceeded_disk_quota?.should be(false) }
    end

    context '20%' do
      let(:quota) { 5000 }
      let(:used) { 1000 }

      it { institution.disk_usage_ratio.should eq(0.2) }
      it { institution.exceeded_disk_quota?.should be(false) }
    end

    context '0%' do
      let(:quota) { 1001 }
      let(:used) { 0 }

      it { institution.disk_usage_ratio.should eq(0) }
      it { institution.exceeded_disk_quota?.should be(false) }
    end

    context '120%' do
      let(:quota) { 5000 }
      let(:used) { 6000 }

      it { institution.disk_usage_ratio.should eq(1.2) }
      it { institution.exceeded_disk_quota?.should be(true) }
    end

    context 'unlimited quota' do
      let(:quota) { 0 }
      let(:used) { 1001 }

      it { institution.disk_usage_ratio.should eq(0) }
      it { institution.exceeded_disk_quota?.should be(false) }
    end

  end

  describe "#recordings_disk_quota=" do
    let(:institution) { FactoryGirl.create(:institution) }

    context 'using a filesize' do
      before { institution.update_attributes(recordings_disk_quota: '50 Mb'); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(50*(10**6)) }
    end

    context 'using another filesize' do
      before { institution.update_attributes(recordings_disk_quota: '50 Mib'); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(50*(1024**2)) }
    end

    context 'using a filesize without the b (300 M -> 300 Mb)' do
      before { institution.update_attributes(recordings_disk_quota: '300 M'); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(300*(10**6)) }
    end

    context 'using a filesize without the b (20 G -> 20 Gb)' do
      before { institution.update_attributes(recordings_disk_quota: '20 G'); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(20*(10**9)) }
    end

    context 'using a number of bytes' do
      before { institution.update_attributes(recordings_disk_quota: 8000); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(8000) }
    end

    context 'using an empty value' do
      before { institution.update_attributes(recordings_disk_quota: ''); institution.reload }
      it { institution.recordings_disk_quota.to_i.should eq(0) }
    end

    context 'using an invalid value' do
      before { institution.update_attributes(recordings_disk_quota: 'incorrect') }
      it { institution.should_not be_valid }
      it { institution.errors[:recordings_disk_quota].size.should eq(1) }
    end

  end

  describe "#update_recordings_disk_used!" do
    let(:target) { FactoryGirl.create(:institution) }
    let(:other_institution) { FactoryGirl.create(:institution) }

    before do
      owners.each_with_index { |owner, i| owner.bigbluebutton_room.recordings << recordings[i] }
      target.update_recordings_disk_used!
    end

    context 'some recordings' do
      let(:recordings) {[
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 2),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 3),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 4)
      ]}
      let(:owners) {[
        FactoryGirl.create(:user, institution: target),
        FactoryGirl.create(:space_with_associations, institution: target),
        FactoryGirl.create(:user, institution: target)
      ]}

      it { target.recordings_disk_used.to_i.should eq(9) }
    end

    context 'with recordings on spaces and users of multiple institutions' do
      let(:recordings) {[
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 10),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 20),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 40),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 100),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 200),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 400),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 800),
        FactoryGirl.create(:bigbluebutton_recording, published: true, size: 1600)
      ]}
      let(:owners) {[
        FactoryGirl.create(:user, institution: target),
        FactoryGirl.create(:user, institution: target),
        FactoryGirl.create(:space_with_associations, institution: target),
        FactoryGirl.create(:space_with_associations, institution: target),
        FactoryGirl.create(:user, institution: other_institution),
        FactoryGirl.create(:user, institution: other_institution),
        FactoryGirl.create(:space_with_associations, institution: other_institution),
        FactoryGirl.create(:space_with_associations, institution: other_institution)
      ]}

      it { target.recordings_disk_used.should eq(170) }
      it { other_institution.recordings_disk_used.to_i.should eq(0) } # method has not been called
      it {
        other_institution.update_recordings_disk_used!
        other_institution.recordings_disk_used.to_i.should eq(3000)
      }
    end

    context 'no recordings' do
      let(:recordings) { [] }
      let(:owners) { [] }

      it { target.recordings_disk_used.to_i.should eq(0) }
    end
  end

  describe "#add_member!" do

    context "when user has no previous institution" do
      let(:user) { FactoryGirl.create(:user) }
      let(:target) { FactoryGirl.create(:institution) }

      it { expect { target.add_member!(user) }.to change(target.users, :count).by(+1) }
    end

    context "when user has a previous institution" do
      let(:user) { FactoryGirl.create(:user) }
      let(:target) { FactoryGirl.create(:institution) }
      let(:previous) { FactoryGirl.create(:institution) }
      before(:each) { previous.add_member!(user) }

      it { expect { target.add_member!(user) }.to change(target.users, :count).by(+1) }
      it { expect { target.add_member!(user) }.to change(previous.users, :count).by(-1) }
    end
  end

  describe "#remove_member!" do
    context "when user is not in the institution" do
      let(:user) { FactoryGirl.create(:user) }
      let(:target) { FactoryGirl.create(:institution) }
      it { expect { target.remove_member!(user) }.not_to change(target.users, :count) }
    end

    context "when user is in the institution" do
      let(:target) { FactoryGirl.create(:institution) }
      let(:user) { FactoryGirl.create(:user, :institution => target) }
      it {
        user # force the user to be created before the call below
        expect { target.remove_member!(user) }.to change(target.users, :count).by(-1)
      }
    end
  end

  it "#unapproved_users"

  it "#to_json"

  describe "#full_name" do
    context "returns the name and the acronym if there's an acronym" do
      let(:target) { FactoryGirl.create(:institution, :name => "Any Name", :acronym => "YAAC") }
      subject { target.full_name }
      it { should eql("Any Name (YAAC)") }
    end

    context "returns the name only if there acronym is nil" do
      let(:target) { FactoryGirl.create(:institution, :name => "Any Name", :acronym => nil) }
      subject { target.full_name }
      it { should eql("Any Name") }
    end

    context "returns the name only if there acronym is empty" do
      let(:target) { FactoryGirl.create(:institution, :name => "Any Name", :acronym => "") }
      subject { target.full_name }
      it { should eql("Any Name") }
    end
  end

  describe "#user_role" do
    context "returns the name of the role for the target user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:target) { FactoryGirl.create(:institution) }

      context "if a normal user" do
        before { target.add_member!(user, "User") }
        it { target.user_role(user).should eql("User") }
      end

      context "if an admin" do
        before { target.add_member!(user, "Admin") }
        it { target.user_role(user).should eql("Admin") }
      end
    end
  end

  describe "#recordings" do
    let(:target) { FactoryGirl.create(:institution) }
    let(:other_institution) { FactoryGirl.create(:institution) }

    before do
      owners.each_with_index { |owner, i| owner.bigbluebutton_room.recordings << recordings[i] }
    end

    context 'with recordings on spaces and users of multiple institutions' do
      let(:recordings) {[
        FactoryGirl.create(:bigbluebutton_recording, published: true),
        FactoryGirl.create(:bigbluebutton_recording, published: true),
        FactoryGirl.create(:bigbluebutton_recording, published: true),
        FactoryGirl.create(:bigbluebutton_recording, published: true)
      ]}
      let(:owners) {[
        FactoryGirl.create(:user, institution: target),
        FactoryGirl.create(:space_with_associations, institution: target),
        FactoryGirl.create(:user, institution: other_institution),
        FactoryGirl.create(:space_with_associations, institution: other_institution),
      ]}

      it { target.recordings.should include(recordings[0]) }
      it { target.recordings.should include(recordings[1]) }
      it { target.recordings.should_not include(recordings[2]) }
      it { target.recordings.should_not include(recordings[3]) }
    end

    context 'no recordings' do
      let(:recordings) { [] }
      let(:owners) { [] }

      it { target.recordings.should be_empty }
    end
  end

  describe "abilities" do
    set_custom_ability_actions([:users, :spaces])

    subject { ability }
    let(:ability) { Abilities.ability_for(user) }
    let(:target) { FactoryGirl.create(:institution) }

    context "when is an anonymous user" do
      let(:user) { User.new }
      it { should_not be_able_to_do_anything_to(target) }
    end

    context "when is a registered user" do
      let(:user) { FactoryGirl.create(:user) }

      context "that's not a member of the institution" do
        it { should_not be_able_to_do_anything_to(target) }
      end

      context "that's a normal member of the institution" do
        before { target.add_member!(user, Role.default_role.name) }
        it { should_not be_able_to_do_anything_to(target) }
      end

      context "that's an admin of the institution" do
        before { target.add_member!(user, 'Admin') }
        it { should_not be_able_to_do_anything_to(target).except([:show, :index, :users, :spaces]) }
      end
    end

    context "when is a superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      it { should be_able_to(:manage, target) }
    end
  end

end
