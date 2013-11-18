class AddUserLimitToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :user_limit, :integer
  end
end
