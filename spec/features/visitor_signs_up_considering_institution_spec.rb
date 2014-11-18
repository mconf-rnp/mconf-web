require 'spec_helper'
require 'support/feature_helpers'

feature 'Visitor signs up considering institution' do

  context 'can select an institution when registering' do
    let!(:institution) { FactoryGirl.create(:institution) }
    before {
      attrs = {
        _full_name: 'Valid User Name',
        email: 'valid@example.com',
        username: 'username',
        password: 'password',
        institution_id: institution.id
      }
      register_with attrs
    }

    it { current_path.should eq(my_home_path) }
    it { page.find("#user-notifications").should have_link('', :href => new_user_confirmation_path) }
    it { has_success_message(I18n.t('devise.registrations.signed_up')) }
    it { page.should have_content('Logout') }

    it "sees the institution set in the profile page" do
      visit edit_user_profile_path(User.last)
      expect(page).to have_field('profile[organization]', with: institution.name, disabled: true)
    end
  end
end
