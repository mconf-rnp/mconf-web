class AddRequireSpaceApprovalAndForbidUserSpaceCreationToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :require_space_approval, :boolean, default: true
    add_column :institutions, :forbid_user_space_creation, :boolean, default: true
  end
end
