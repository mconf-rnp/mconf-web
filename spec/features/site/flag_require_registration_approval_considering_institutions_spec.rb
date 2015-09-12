require 'spec_helper'
require 'support/feature_helpers'

include ActionView::Helpers::SanitizeHelper

feature 'Behaviour of the flag Site#require_registration_approval considering institutions' do

  context "if admin approval is required" do
    before {
      Site.current.update_attributes(require_registration_approval: true)
    }

    context "and the user's institution has multiple admins" do
      let!(:institution) { FactoryGirl.create(:institution) }
      let(:attrs) {
        FactoryGirl.attributes_for(:user).merge({ :institution_id => institution.id })
          .slice(:username, :_full_name, :email, :password, :institution_id)
      }
      let!(:inst_admin) {
        u = FactoryGirl.create(:user)
        institution.add_member! u, "Admin"
        u
      }
      let!(:inst_admin2) {
        u = FactoryGirl.create(:user)
        institution.add_member! u, "Admin"
        u
      }

      context "registering in the website" do
        before {
          with_resque do
            expect { register_with(attrs) }.to change{ User.count }.by(1)
          end
        }

        it { User.last.confirmed?.should be false }
        it { User.last.approved?.should be false }

        it "sends the correct confirmation email to the user", with_truncation: true do
          mail = email_by_subject t('devise.mailer.confirmation_instructions.subject')
          mail.should_not be_nil
          mail.body.encoded.should_not match(/http.*users\/confirmation*/)
          mail.body.encoded.should match(t('devise.mailer.confirmation_instructions.confirmation_pending'))
        end
       end

      context "signing in via shibboleth for the first time, generating a new account" do
        before {
          institution.update_attributes(identifier: attrs[:email].gsub(/.*\@/, ''))
          enable_shib
          setup_shib attrs[:_full_name], attrs[:email], attrs[:email]

          with_resque do
            expect {
              visit shibboleth_path
              click_button t('shibboleth.associate.new_account.create_new_account')
            }.to change{ User.count }.by(1)
          end
        }

        it { User.last.confirmed?.should be true }
        it { User.last.approved?.should be false }

        it "doesn't a confirmation email to the user", with_truncation: true do
          mail = email_by_subject t('devise.mailer.confirmation_instructions.subject')
          mail.should be_nil
        end

      end

      it "signing in via LDAP for the first time, generating a new account"
    end
  end

end
