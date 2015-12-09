# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe MwebEvents::Event do
  skip "abilities (using permissions, space admins, event organizers)"

  describe "abilities" do
    set_custom_ability_actions([])

    subject { ability }
    let(:ability) { Abilities.ability_for(user) }

    context "in the space events view" do

      context "for an institutional admin" do
        let(:user) { FactoryGirl.create(:user) }
        let(:institution) { user.institution }
        let(:space) { FactoryGirl.create(:space_with_associations, public: true) }
        let(:target) { FactoryGirl.build(:event, owner: space) }

        before(:each) {
          institution.add_member!(user, 'Admin')
        }

        context "in a space belonging to his institution" do
          before { space.update_attributes(institution: institution) }

          it { should be_able_to_do_everything_to(target) }
        end

        context "in a space not belonging to his institution" do

          it { should_not be_able_to_do_everything_to(target).except([:show, :index]) }
        end
      end

    end

  end
end
