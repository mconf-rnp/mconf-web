class AddSharedSecretToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :shared_secret, :string
  end
end
