class AddInstitutionToSpace < ActiveRecord::Migration
  def change
    add_column :spaces, :institution_id, :integer
  end
end
