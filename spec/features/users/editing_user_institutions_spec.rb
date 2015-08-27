require 'spec_helper'
require 'support/feature_helpers'

feature "Editing user institutions" do

  context "a normal user can't edit his institution" do
    let(:user) { FactoryGirl.create(:user) }

    before { sign_in_with user.email, user.password }
    it { current_path.should eq(my_home_path) }
    it {
      visit edit_user_path(user)
      expect(page).not_to have_field('user[institution_id]')
    }
  end

  context "an admin can edit his institution" do
    let(:new_institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:user, superuser: true) }

    before { sign_in_with user.email, user.password }
    it { current_path.should eq(my_home_path) }

    context "has the field to edit the institution" do
      before {
        visit edit_user_path(user)
      }
      it { expect(page).to have_field('user[institution_id]') }

      context "can set a new institution" do
        before {
          fill_in 'user[institution_id]', with: new_institution.id
          click_button "Save"
        }
        it { has_success_message(I18n.t('user.updated')) }

        context do
          before { visit edit_user_path(user) }
          it { expect(page).to have_field('user[institution_id]', with: new_institution.id) }
        end
      end
    end
  end

  context "an admin can edit other user's institution" do
    let(:new_institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:user, superuser: true) }
    let(:other_user) { FactoryGirl.create(:user) }

    before { sign_in_with user.email, user.password }
    it { current_path.should eq(my_home_path) }

    context "has the field to edit the institution" do
      before {
        visit edit_user_path(other_user)
      }
      it { expect(page).to have_field('user[institution_id]') }

      context "can set a new institution" do
        before {
          fill_in 'user[institution_id]', with: new_institution.id
          click_button "Save"
        }
        it { has_success_message(I18n.t('user.updated')) }
        context do
          before { visit edit_user_path(other_user) }
          it { expect(page).to have_field('user[institution_id]', with: new_institution.id) }
        end
      end
    end
  end

  # they can't edit anyone's institution, but testing with someone in their institution is the edge case
  context "an institution admin can't edit the institution of users in his institution" do
    let(:institution) { FactoryGirl.create(:institution) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    before {
      institution.add_member!(user, "Admin")
      institution.add_member!(other_user, "User")
      sign_in_with user.email, user.password
    }
    it { current_path.should eq(my_home_path) }
    it {
      visit edit_user_path(other_user)
      expect(page).not_to have_field('user[institution_id]')
    }
  end
end
