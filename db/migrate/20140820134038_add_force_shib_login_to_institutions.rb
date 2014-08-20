class AddForceShibLoginToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :force_shib_login, :boolean, :default => false
  end
end
