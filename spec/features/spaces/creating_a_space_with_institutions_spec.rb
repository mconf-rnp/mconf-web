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

  feature "creating a space as a normal user" do

    scenario "in a non moderated institution" do
      user.update_attributes(institution: institution)

      attrs = FactoryGirl.attributes_for(:space, public: true)
      login_as(user, :scope => :user)

      create_space_from_attrs(attrs)

      Space.last.should be_approved
      current_path.should eq(space_path(Space.last))
      page.should have_content(attrs[:name])
    end

    scenario "in a moderated institution" do
      user.update_attributes(institution: institution)
      institution.update_attributes(require_space_approval: true)

      login_as(user, :scope => :user)

      attrs = FactoryGirl.attributes_for(:space)
      create_space_from_attrs(attrs)

      Space.last.should_not be_approved
      current_path.should eq(spaces_path)
      has_success_message t('space.created_waiting_moderation')

      page.should_not have_content(attrs[:name])

      visit spaces_path(my_spaces: 'true')
      page.should have_content(attrs[:name])
      page.should have_selector('.waiting-approval', count: 1)
      page.should have_selector('.icon-mconf-waiting-moderation', count: 1)
    end

    scenario "in an institution with space creation forbidden" do
      user.update_attributes(institution: institution)
      institution.update_attributes(forbid_user_space_creation: true)

      login_as(user, :scope => :user)

      visit spaces_path
      expect{ find_link('', href: new_space_path) }.to  raise_error

      visit new_space_path

      current_path.should eq(spaces_path)
      has_failure_message t('spaces.error.creation_forbidden')
    end

  end

  feature "creating a space as an institution admin" do

    scenario "in a non moderated institution" do
      user.update_attributes(institution: institution)
      user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)

      attrs = FactoryGirl.attributes_for(:space)
      login_as(user, :scope => :user)

      create_space_from_attrs(attrs)

      Space.last.should be_approved
      current_path.should eq(space_path(Space.last))
      page.should have_content(attrs[:name])
    end

    scenario "in a moderated institution" do
      user.update_attributes(institution: institution)
      institution.update_attributes(require_space_approval: true)
      user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)

      attrs = FactoryGirl.attributes_for(:space)
      login_as(user, :scope => :user)

      create_space_from_attrs(attrs)

      Space.last.should be_approved
      current_path.should eq(space_path(Space.last))
      page.should have_content(attrs[:name])
    end

    scenario "in an institution with space creation forbidden" do
      user.update_attributes(institution: institution)
      institution.update_attributes(forbid_user_space_creation: true)
      user.permissions.last.update_attributes(role: Role.where(name: 'Admin').first)
      login_as(user, :scope => :user)

      visit spaces_path
      page.find_link('', href: new_space_path).should be_visible

      visit new_space_path
      current_path.should eq(new_space_path)
    end

  end

end
