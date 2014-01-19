class AddCanRecordLimitToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :can_record_limit, :integer
  end
end
