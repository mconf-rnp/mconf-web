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

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:acronym) }

  describe ".spaces" do
    let(:target) do
      target = FactoryGirl.create(:institution)
      target.spaces << FactoryGirl.create(:space)
      target.spaces << FactoryGirl.create(:space)
      target
    end

    it { target.spaces.size.should be(2) }
    it { expect {target.spaces << FactoryGirl.create(:space)}.to change(target.spaces, :count).by(+1) }
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
  it "#full?"
  it "#users_that_can_record"
  it "#can_record_full?"
  it "#admins"

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
    context "returns the name and the acronym" do
      let(:target) { FactoryGirl.create(:institution, :name => "Any Name", :acronym => "YAAC") }
      subject { target.full_name }
      it { should eql("Any Name (YAAC)") }
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

  describe "abilities" do
    subject { ability }
    let(:ability) { Abilities.ability_for(user) }
    let(:target) { FactoryGirl.create(:institution) }

    context "when is an anonymous user" do
      let(:user) { User.new }
      it { should_not be_able_to_do_anything_to(target).except(:read) }
    end

    context "when is a registered user" do
      let(:user) { FactoryGirl.create(:user) }

      context "that's not a member of the institution" do
        it { should_not be_able_to_do_anything_to(target).except(:read) }
      end

      context "that's a member of the institution" do
        before { target.add_member!(user, Role.default_role.name) }
        it { should_not be_able_to_do_anything_to(target).except(:read) }
      end

      context "that's an admin of the institution" do
        before { target.add_member!(user, 'Admin') }
        it { should_not be_able_to_do_anything_to(target).except([:read, :update, :edit]) }
      end
    end

    context "when is a superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      it { should be_able_to(:manage, target) }
    end
  end

end
