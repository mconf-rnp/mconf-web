require 'spec_helper'

feature 'Visitor logs in considering institution' do
  before(:each) {
    @user = FactoryGirl.create(:user, :username => 'user', :password => 'password')
  }

  scenario "can't sign in if his institution forces login via shibboleth" do
    institution = FactoryGirl.create(:institution, acronym: "UFRGS", force_shib_login: true)
    @user.institution = institution
    @user.save!

    visit new_user_session_path
    sign_in_with @user.username, @user.password

    expect(current_path).to eq(user_session_path)
    expect(page).to have_notification(I18n.t('devise.failure.force_shib_login'))
  end
end
