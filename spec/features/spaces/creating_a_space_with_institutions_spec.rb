# -*- coding: utf-8 -*-
require "spec_helper"
require "support/feature_helpers"

def create_space_from_attrs attrs
  visit new_space_path
  fill_in "space[name]", with: attrs[:name]
  fill_in "space[permalink]", with: attrs[:permalink]
  fill_in "space[description]", with: attrs[:description]

  if attrs[:public] == true
    check "space[public]"
  else
    uncheck "space[public]"
  end

  click_button t("_other.create")
end

feature "Creating a space when institutions are present" do
  let!(:user) { FactoryGirl.create(:user) }
  let(:institution) { FactoryGirl.create(:institution) }

  context "creating a space as a normal user" do

    context "in a non moderated institution" do
      let(:attrs) { FactoryGirl.attributes_for(:space, public: true, disabled: false) }
      before {
        user.update_attributes(institution: institution)
        login_as(user, :scope => :user)
        create_space_from_attrs(attrs)
      }

      it { Space.last.should be_approved }
      it { current_path.should eq(space_path(Space.last)) }
      it { page.should have_content(attrs[:name]) }
    end

    context "in a moderated institution" do
      let(:attrs) { FactoryGirl.attributes_for(:space) }
      before {
        user.update_attributes(institution: institution)
        institution.update_attributes(require_space_approval: true)
        login_as(user, :scope => :user)
        create_space_from_attrs(attrs)

      }

      it { Space.last.should_not be_approved }
      it { current_path.should eq(spaces_path) }
      it { has_success_message t('space.created_waiting_moderation') }

      it { page.should_not have_content(attrs[:name]) }

      context 'space appears in user spaces' do
        before { visit spaces_path(my_spaces: 'true') }

        it { page.should have_content(attrs[:name]) }
        it { page.should have_selector('.waiting-approval', count: 1) }
        it { page.should have_selector('.icon-mconf-waiting-moderation', count: 1) }
      end
    end

    context "in an institution with space creation forbidden" do
      before {
        user.update_attributes(institution: institution)
        institution.update_attributes(forbid_user_space_creation: true)

        login_as(user, :scope => :user)
        visit spaces_path
      }

      it { expect{ find_link('', href: new_space_path) }.to  raise_error }

      context 'cant create a space' do
        before { visit new_space_path }

        it { current_path.should eq(spaces_path) }
        it { has_failure_message t('spaces.error.creation_forbidden') }
      end
    end

  end

  feature "creating a space as an institution admin" do

    context "in a non moderated institution" do
      let(:attrs) { FactoryGirl.attributes_for(:space, public: true) }
      before {
        user.update_attributes(institution: institution)
        user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)

        login_as(user, :scope => :user)

        create_space_from_attrs(attrs)
      }

      it { Space.last.should be_approved }
      it { current_path.should eq(space_path(Space.last)) }
      it { page.should have_content(attrs[:name]) }
    end

    context "in a moderated institution" do
      let(:attrs) { FactoryGirl.attributes_for(:space, public: true) }
      before {
        user.update_attributes(institution: institution)
        institution.update_attributes(require_space_approval: true)
        user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)
        login_as(user, :scope => :user)

        create_space_from_attrs(attrs)
      }

      it { Space.last.should be_approved }
      it { current_path.should eq(space_path(Space.last)) }
      it { page.should have_content(attrs[:name]) }
    end

    context "in an institution with space creation forbidden" do
      before {
        user.update_attributes(institution: institution)
        institution.update_attributes(forbid_user_space_creation: true)
        user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)
        login_as(user, :scope => :user)

        visit spaces_path
      }

      it { page.find_link('', href: new_space_path).should be_visible }

      context 'can create a space' do
        before { visit new_space_path }
        it { current_path.should eq(new_space_path) }
      end
    end

  end

end
