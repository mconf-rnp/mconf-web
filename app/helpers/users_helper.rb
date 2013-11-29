require 'version'

module UsersHelper

  def user_category user
    if user.superuser
      icon_superuser + t('_other.user.administrator')
    elsif user.institution && user.institution.admins.include?(user)
      icon_admin_institution + t('user.institutional_admin')
    else
      icon_user + t('_other.user.normal_user')
    end
  end

end
