class ChangeInstitutionsIdentifierToText < ActiveRecord::Migration
  def change
    change_column :institutions, :identifier, :text
  end
end
