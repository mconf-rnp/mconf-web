class AddRequireSpaceApprovalAndForbidUserSpaceCreationToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :require_space_approval, :boolean, default: false
    add_column :institutions, :forbid_user_space_creation, :boolean, default: false
  end
end
