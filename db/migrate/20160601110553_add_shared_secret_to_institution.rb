class AddSharedSecretToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :secret, :string
  end
end
