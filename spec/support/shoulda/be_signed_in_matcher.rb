# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# Ensures the model has an attr_accessor, attr_reader or attr_writer
# Examples:
#   it { should_authorize(Model, :method, :via => :http_method, :parameters) }
#   it { should_authorize(User, :index) }
#   it { should_authorize(an_instance_of(Space), :create, :via => :post, :space => {:name => 'space'} ) }

module Shoulda
  module Matchers
    module ActiveModel # :nodoc

      # Usage example: accept_nested_attributes_for(:address)
      def be_signed_in
        BeSignedInMatcher.new
      end

      class BeSignedInMatcher < ValidationMatcher # :nodoc:
        def initialize
        end

        def matches?(controller)
          controller.current_user != nil
        end

        def description
          "ensure there's a user signed in"
        end

        def failure_message
          "Expected to have a user signed in"
        end

        def negative_failure_message
          "Did not expected to have a user signed in"
        end

      end
    end
  end
end
