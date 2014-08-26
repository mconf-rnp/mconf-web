require 'spec_helper'

def enable_shib
  Site.current.update_attributes(
    :shib_enabled => true,
    :shib_name_field => "Shib-inetOrgPerson-cn",
    :shib_email_field => "Shib-inetOrgPerson-mail",
    :shib_principal_name_field => "Shib-eduPerson-eduPersonPrincipalName"
  )
end

def setup_shib name, email, principal
  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new(app, :headers => {
      "Shib-inetOrgPerson-cn" => name,
      "Shib-inetOrgPerson-mail" => email,
      "Shib-eduPerson-eduPersonPrincipalName" => principal
    })
  end
end

feature 'User signs in via shibboleth' do

  context 'with shibboleth enabled' do
    subject { page }

    let(:identifier) { 'institution.org' }
    let(:attrs) { FactoryGirl.attributes_for(:user, :email => "user@#{identifier}") }
    before { enable_shib }
    before { setup_shib attrs[:_full_name], attrs[:email], attrs[:email] }

    context 'on site frontpage' do
      before { visit root_path }

      it { should have_link '', :href => shibboleth_path }
      it { should have_content t('frontpage.show.login.click_here') }
    end

    context 'and valid shib data' do
      context "can't sign in for the first time if his institution from the federation is not registered" do
        before { visit shibboleth_path }

        it { has_failure_message }
        it { current_path.should eq(root_path) }
      end

      context "can access if his institution from the federation is registered" do
        let(:institution) { FactoryGirl.create(:institution, :identifier => identifier) }
        before {
          institution
          visit shibboleth_path
        }

        it { current_path.should eq(shibboleth_path) }

        it { should have_content t('shibboleth.associate.existent_account.title') }
        it { should have_button t('shibboleth.associate.existent_account.link_to_this_account') }

        it { should have_content t('shibboleth.associate.new_account.title') }
        it { should have_button t('shibboleth.associate.new_account.create_new_account') }

        context 'associating with account' do
          context 'with invalid data' do
            before { click_button t('shibboleth.associate.existent_account.link_to_this_account') }

            it { has_failure_message }
            it { current_path.should eq(shibboleth_path) }
          end

          context 'with valid data' do
            let(:user) { FactoryGirl.create(:user, :password => '123456', :password_confirmation => '123456') }

            before {
              fill_in 'user[login]', :with => user.username
              fill_in 'user[password]', :with => user.password
              click_button t('shibboleth.associate.existent_account.link_to_this_account')
            }

            it { current_path.should eq(my_home_path) }
          end

        end

        context 'creating a new account' do
          before { click_button t('shibboleth.associate.new_account.create_new_account') }

          it { current_path.should eq(my_home_path) }
        end
      end

      context "can access if already has an account, even if his institution from the federation is not registered" do
      end
    end
  end

end
