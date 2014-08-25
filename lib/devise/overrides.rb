require 'devise/strategies/database_authenticatable'
Devise::Strategies::DatabaseAuthenticatable.class_eval do

  # must use the 'unless' to prevent this from being called twice and resulting in
  # a recursion (happens a lot in development)
  alias_method :super_authenticate!, :authenticate! unless method_defined?(:super_authenticate!)

  # We override #authenticate! to block the authentication in case the local
  # authentication is disabled in the current site.
  # It does the minimum if could do before calling the parent's #authenticate! method
  # that actually does the authentication.
  # Not overriding #valid? for two reasons: #valid? is called way more than #authenticate!,
  # and #authenticate! can return a custom error message.
  def authenticate!
    resource = mapping.to.find_for_database_authentication(authentication_hash)
    return fail(:not_found_in_database) unless resource

    # only some institutions allow local login, others must use shibboleth
    if params.has_key?(:user)
      user = User.where(username: params[:user][:login]).first
      if user && !user.institution.nil? && user.institution.force_shib_login?
        return fail(:force_shib_login)
      end
    end

    super_authenticate!
  end
end
