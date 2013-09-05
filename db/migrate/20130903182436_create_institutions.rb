class CreateInstitutions < ActiveRecord::Migration
  def change
    create_table :institutions do |t|
      t.string :name
      t.string :acronym
      t.string :permalink

      t.timestamps
    end
  end
end
