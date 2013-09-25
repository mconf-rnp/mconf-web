require 'spec_helper'

describe Institution do
  let(:institution) { FactoryGirl.create(:institution) }

  it "creates a new instance given valid attributes" do
    FactoryGirl.build(:institution).should be_valid
  end

  it { should have_many(:permissions).dependent(:destroy) }
  it { should have_many(:users) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of(:permalink) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:acronym) }

  describe ".search" do
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

      context "that's a member of the institution" do
        it { should_not be_able_to_do_anything_to(target).except(:read) }
      end

      context "that's not a member of the institution" do
        it { should_not be_able_to_do_anything_to(target).except(:read) }
      end

      context "that's an institutional admin of the institution" do
        before { target.add_admin!(user) }
        it { should_not be_able_to_do_anything_to(target).except([:read, :update]) }
      end
    end

    context "when is a superuser" do
      let(:user) { FactoryGirl.create(:superuser) }
      it { should be_able_to(:manage, target) }
    end
  end

end
