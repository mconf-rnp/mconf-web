class AddIdentifierToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :identifier, :string
  end
end
