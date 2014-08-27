require 'spec_helper'

include ActionView::Helpers::SanitizeHelper

feature 'User signs in via shibboleth' do

  context 'with shibboleth enabled' do
    subject { page }

    before(:all) {
      @identifier = 'institution.org'
      @attrs = FactoryGirl.attributes_for(:user, :email => "user@#{@identifier}")
    }

    before {
      enable_shib
      setup_shib @attrs[:_full_name], @attrs[:email], @attrs[:email]
    }

    context 'on site frontpage' do
      before { visit root_path }

      it { should have_link '', :href => shibboleth_path }
      it { should have_content t('frontpage.show.login.click_here') }
    end

    context 'and valid shib data' do
      context "can't sign in for the first time if his institution from the federation is not registered" do
        before { visit shibboleth_path }

        it { has_failure_message t('shibboleth.create_association.institution_not_registered') }
        it { current_path.should eq(root_path) }
      end

      context "can access if his institution from the federation is registered" do
        let(:institution) { FactoryGirl.create(:institution, :identifier => @identifier) }
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

            it { has_success_message t('shibboleth.create_association.account_associated', :email => user.email) }
            it { current_path.should eq(my_home_path) }
            it { should have_content user._full_name }
            it { should have_content user.email }
          end

        end

        context 'creating a new account' do
          before { click_button t('shibboleth.associate.new_account.create_new_account') }

          it { has_success_message strip_links(t('shibboleth.create_association.account_created', :url => new_user_password_path)) }
          it { current_path.should eq(my_home_path) }
          it { should have_content @attrs[:_full_name] }
          it { should have_content @attrs[:email] }
        end
      end

      context "can access if already has an account, even if his institution from the federation is not registered" do
        before {
          # first create a new account via shibolleth register
          @institution = FactoryGirl.create(:institution, :identifier => @identifier)
          visit shibboleth_path
          click_button t('shibboleth.associate.new_account.create_new_account')

          # log out and try accessing shibolleth with the same user but
          # without the institution existiting anymore
          @institution.destroy
          logout_user

          # make sure the next logged user is using data from his account and not just creating a new one
          @new_name = 'Newly created and supersecret name'
          User.last.profile.update_attributes :full_name => @new_name

          visit root_path
          click_link t('frontpage.show.login.click_here')
        }

        it { current_path.should eq(my_home_path) }
        it { should have_content @new_name }
        it { should have_content @attrs[:email] }
      end
    end
  end

end
