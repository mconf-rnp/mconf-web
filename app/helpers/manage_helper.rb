module ManageHelper

  def is_institutional_admin user
    role = Role.where(name: 'Admin').first
    user.institution &&
    Permission.where(subject_type: 'Institution', role_id: role.id, user_id: user.id).present?
  end

end