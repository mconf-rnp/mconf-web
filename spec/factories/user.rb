# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

FactoryGirl.define do

  # TODO: Not really unconfirmed as it should, but can't do it right now:
  #   It's triggering an error related to delayed_job (undefined method `tag=').
  #   Uncomment this when delayed_job is removed, see #811.
  #   Search for this same comment in other files as well.
  factory :user_unconfirmed, :class => User do |u|
    u.username
    u.email
    u.sequence(:_full_name) { |n| Forgery::Name.unique_full_name(n) }
    u.association :bigbluebutton_room
    u.association :profile
    u.created_at { Time.now }
    u.updated_at { Time.now }
    u.disabled false
    u.approved true
    u.superuser false
    u.receive_digest { User::RECEIVE_DIGEST_NEVER }
    u.confirmed_at { Time.now }
    u.password { Forgery::Basic.password :at_least => 6, :at_most => 16 }
    u.password_confirmation { |u2| u2.password }
    u.sequence(:institution_name) { |n| Forgery::Name.unique_full_name(n) }
    after(:create) do |u2|
      u2.confirm!
      # set the institution using `institution_name` only if `institution` wasn't
      # already specified
      u2.set_institution(u2.institution_name) if u2.institution.nil?
    end
  end

  factory :user, :parent => :user_unconfirmed do |u|
    # u.confirmed_at { Time.now }
    # after(:create) { |u2| u2.confirm! }
  end

  factory :superuser, :class => User, :parent => :user do |u|
    u.superuser true
  end
end
