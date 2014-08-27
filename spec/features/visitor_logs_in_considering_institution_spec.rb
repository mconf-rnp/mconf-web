require 'spec_helper'

feature 'Visitor logs in considering institution' do
  before(:each) {
    @user = FactoryGirl.create(:user, :username => 'user', :password => 'password')
  }

  feature "can't sign in if his institution forces login via shibboleth" do
    before {
      institution = FactoryGirl.create(:institution, acronym: "UFRGS", force_shib_login: true)
      @user.institution = institution
      @user.save!
    }

    scenario "using the username" do
      visit new_user_session_path
      sign_in_with @user.username, @user.password

      expect(current_path).to eq(user_session_path)
      expect(page).to have_notification(I18n.t('devise.failure.force_shib_login'))
    end

    scenario "using the email" do
      visit new_user_session_path
      sign_in_with @user.email, @user.password

      expect(current_path).to eq(user_session_path)
      expect(page).to have_notification(I18n.t('devise.failure.force_shib_login'))
    end
  end
end
